
using System;
using System.Configuration;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Diagnostics.Eventing.Reader;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data;
using System.Diagnostics;
using System.Reflection;
using System.Windows.Forms;
using System.Windows.Forms.VisualStyles;
using System.ComponentModel;
using System.Xml;
using System.Transactions;


//Custom libraries
using Abc_Notify;
using AutomatedBuild.Properties;
using EnumAbcRunType = Prefix.DeclareWarehouse.EnumAbcRunType;
using Prefix;
using Prefix.Compression.SevenZip;

namespace AutomatedBuild
{
    /// <summary>
    /// Executes an Automated Build Compare run type depending on command line parameter "Task"
    /// Task 97: BuildBcp (ABC)
    /// Task 98: Projections (PAC)
    /// </summary>
    public static partial class RunABC
    {

        public static Notify.BuildInfo buildInfo = new Notify.BuildInfo();
        public static Abc_Notify.Notify mailSender = new Notify(Properties.Settings.Default.EmailServer, Properties.Settings.Default.TestRegion, Properties.Settings.Default.AbcWebURL);
        public static String abcStatusPath;

        /// <summary>
        /// Entry point for ABC runs
        /// </summary>
        /// <param name="args"></param>
        private static void Main(string[] args)
        {
            Boolean RunCriteriaCheck = false;
            int Profile = 0;
            try
            {
                Profile = Properties.Settings.Default.Profile;
            }
            catch (Exception)
            {
                //Do nothing
            }

            //Set connection string
            abcDBConx = ConfigurationManager.ConnectionStrings["AbcDBContext"].ConnectionString;
            mailSender.conxString = abcDBConx;

            //Set run type based on clp Task Parameter
            CommandLineParameters clp = new CommandLineParameters(Environment.CommandLine);
            switch (clp.Task)
            {
                case 97:
                    abcRunType = EnumAbcRunType.AbcCore;
                    break;
                case 98:
                    abcRunType = EnumAbcRunType.Projection;
                    break;
                default:
                    LogEvent(String.Format("Task {0} is not valid.", clp.Task), FATAL);
                    break;
            }
            mailSender.abcRunType = abcRunType;

            // set up pv based on profile
            Prefix.StartUpCfg.Set_Drive_Path_Warehouse(Profile, pv);

            try
            {
                abcStatusPath = pv.StatusPath.Replace("\\Status\\", "\\AbcStatus\\ABC\\");
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Error setting abcStatusPath: {}", ex.Message), FATAL);
            }

            switch (abcRunType)
            {
                case EnumAbcRunType.AbcCore:
                    outputPath = Path.Combine(abcStatusPath, "ABC_DATA");
                    runType = "B";
                    break;
                case EnumAbcRunType.Projection:
                    outputPath = Path.Combine(abcStatusPath, "PAC_DATA");
                    runType = "P";
                    break;
            }

            LogEvent(String.Format("STARTING AUTOMATED BUILD COMPARE >> RUN TYPE: {0}", abcRunType.ToString()), 0);
            LogEvent(String.Format("Connection String: {0}", abcDBConx), 0);
            LogEvent(String.Format("Status Path: {0}", abcStatusPath), 0);  // E:\Prefix\CI6\Prefix\AbcStatus\ABC\
            LogEvent(String.Format("Output Path: {0}", outputPath), 0);
            LogEvent(String.Format("Profile: {0}", Profile), 0);

            // Send delta assignment reminders
            //DEBUG Comment in 
            SendDeltaReminders();
            //DEBUG

            //DEBUG ONLY - Run to here to just assign deltas. Update BuildId, buildInfo.BuildNumber, buildInfo.PreviousBuildNumber before running
            //Comment out - This will be done at the end of the run
            //buildInfo.BuildId = 100; buildInfo.PreviousBuildNumber = "2015.03.13.2213"; buildInfo.BuildNumber = "2015.03.13.2214";  
            //AutoAssignDeltas(false); Environment.Exit(1);
            //DEBUG ONLY

            RunCriteriaCheck = (abcDBConx.Length > 0) && (null != abcStatusPath) && (Profile > 0);

            if (RunCriteriaCheck)
            {
                //NOTE: VersionIsNew sets the BuildNumber for the run
                RunCriteriaCheck = (VersionIsNew() || Properties.Settings.Default.OverrideVersionCheck);
            }

            if (RunCriteriaCheck)
            {
                //Delete prior day and copy current day to prior day. 
                //Also: LOOPS TROUGH THE LIST OF BUILDS THAT HAD ALL OF THEIR DELTAS RESOLVED SINCE LAST RUN and Removes VAR records for same
                RunCriteriaCheck = DailyReset();
            }

            //Execute run type specific pre-run data conditioning methods
            if (RunCriteriaCheck)
            {
                if (abcRunType == EnumAbcRunType.Projection)
                {
                    RunCriteriaCheck = ConditionPoliciesForPac();
                }
            }

            //Do run if RunCriteria are OK and there has not been a check-in or Rerun flag is set, else exit and send Run Skipped message
            if (RunCriteriaCheck)
                {
                    SendEmail("RunStarted");

                    //Ensure that the outputPath folder exists
                    Directory.CreateDirectory(outputPath);

                    //Saves n archived versions of the build output according to config setting
                    //and clears outputPath 
                    ArchiveOutputFiles();

                    //Get Path to CV command and run CV to create daily build output Files
                    String cvCmd = Properties.Settings.Default.CVPath;
                    if (!File.Exists(cvCmd))
                    {
                        String errMsg = String.Format("Cash Value executable not found at: {0}", cvCmd);
                        LogEvent(errMsg, FATAL);
                    }

                    String argString = String.Format(" /usr 9876 /sess 9876 /prof {0} /Task {1}", Profile, clp.Task.ToString());
                    LogEvent(String.Format("Cash Value Command:  {0}", cvCmd + argString), 0);

                    //Write BuildBcp output to the abcStatusPath
                    ExecuteCashValueCommand(cvCmd + argString);
                    LogInfoEvent("Cash Value completed.");

                    //Move files to outputPath to separate folder for each run type (ABC, PAC, etc.)
                    CopyOutputFiles(abcStatusPath, outputPath, true);
                    LogInfoEvent(String.Format("Data files moved from {0} to {1}.",
                        abcStatusPath, outputPath));

                    //Local: load from output path
                    String loadPath = outputPath + "\\";
                    //
                    //Remote:
                    if (Properties.Settings.Default.UseRemoteServer)
                    {
                        //Clear the remote copy folder on the DB server
                        if (Directory.Exists(Properties.Settings.Default.RemoteServer_CopyPath))
                        {
                            Array.ForEach(Directory.GetFiles(Properties.Settings.Default.RemoteServer_CopyPath), File.Delete);
                        }
                        //Copy the consolidated files to the remote copy path, but leave a copy for archiving
                        CopyOutputFiles(outputPath,
                            Properties.Settings.Default.RemoteServer_CopyPath, false);
                        //same path as outputPath but as seen by the DB server
                        loadPath = Properties.Settings.Default.RemoteServer_LoadPath;
                    }
                    else
                    {
                        //Override for custom load path [usually empty for local]
                        if (Settings.Default.LoadDataPath != null)
                        {
                            if (Settings.Default.LoadDataPath.Length > 0)
                            {
                                loadPath = Settings.Default.LoadDataPath;
                            }
                        }
                    }
                    LogInfoEvent(String.Format("Data load path: {0}", loadPath));

                    //bulk insert the data into the ABC tables
                    LoadDailyData(loadPath, System.Environment.MachineName + "1z");

                //DEBUG - Comment Out
                //buildInfo.BuildId = 107; buildInfo.PreviousBuildNumber = "2015.03.13.2223"; buildInfo.BuildNumber = "2015.03.13.2225";  
                //DEBUG

                //Find differences and load variances tables
                DoBuildCompare();

                //Find and logs any Policies data that was dropped by Cash Value
                CheckForMissingPolicyData();

                //Get high level run results
                UpdateBuildInfo();

                //Auto-Assign Deltas
                if (Boolean.Parse(Properties.Settings.Default.AutoAssignDeltas))
                {
                    AutoAssignDeltas(buildInfo.Delta);
                }

                //Update final error count
                UpdateBuildInfo(true);

                //Run Complete
                SendEmail("RunComplete");

                //If Errors, send error message
                if (buildInfo.ErrorCount > 0)
                {
                    SendEmail("RunErrors");
                }

                //If Deltas, send deltas message
                if (buildInfo.DeltaCount > 0)
                {
                    SendEmail("RunDeltas");
                }

                LogEvent("END: AUTOMATED BUILD COMPARE RUN", 0);

            }
            else
            {
                if (!newCheckIn)
                {
                    LogEvent("NO RUN NEEDED: No check-ins have occurred since the last run.");
                    SendEmail("RunSkipped");
                }
                else
                {
                    LogEvent("=====>>> RUN ABORTED <<<===== One or more configuration criteria were not met.", 2);
                    SendEmail("RunErrors");
                }
            }
        }

        //Audit check: detect and log all Policies that are missing from P or C in the BC tables
        private static void CheckForMissingPolicyData()
        {
            LogInfoEvent();

            try
            {
                DataSet ds = new DataSet("MissingPolicyDataList");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_FindMissingPolicyData", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        sqlComm.Parameters.AddWithValue("@runType", runType);
                        sqlComm.CommandTimeout = 1800;
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count == 0)
                        {
                            String errMsg = "No missing Policy data was detected.";
                            LogEvent(errMsg, 1);
                        }
                        else
                        {
                            for (Int16 i = 0; i < ds.Tables[0].Rows.Count; i++)
                            {
                                String warnMsg = ds.Tables[0].Rows[i]["MissingFrom"] + " data for policy " + (Int32)ds.Tables[0].Rows[i]["Number"] + " is missing from " + ds.Tables[0].Rows[i]["TableName"];
                                LogEvent(warnMsg, 1);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
            return;
        }

        //Calculates Pac Projections and creates appropriate TransactionDaily records for those Projections
        //Captures a list of Policies and Projection Types for debug purposes but does nothing with the list
        private static Boolean ConditionPoliciesForPac()
        {
            LogInfoEvent();

            try
            {
                DataSet ds = new DataSet("ProjectionPolicyList");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_ConditionPoliciesForPac", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count == 0)
                        {
                            String errMsg = "No Projections available for Build policies";
                            LogEvent(errMsg, FATAL);
                        }
                        else
                        {
                            String errMsg = String.Format("Running Projections for {0} policies", ds.Tables[0].Rows.Count);
                            LogInfoEvent(errMsg);
                        }

                        List<PolicyProjection> PolicyProjectionList = new List<PolicyProjection>();
                        for (byte i = 0; i < ds.Tables[0].Rows.Count; i++)
                        {
                            PolicyProjection nextPolicyProjection = new PolicyProjection((Int32)ds.Tables[0].Rows[i]["Number"],
                                (Int16)ds.Tables[0].Rows[i]["TrxCode"]);
                            PolicyProjectionList.Add(nextPolicyProjection);
                        }
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return false;
            }
        }

        private static Boolean VersionIsNew()
        {
            LogInfoEvent();

            try
            {
                DataSet ds = new DataSet("PriorRunVersion");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    //If version is already in BuildInfo NewVersionCheck returns empty string, else returns version number for new run
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_NewVersionCheck", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        sqlComm.Parameters.AddWithValue("@runType", runType);
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count != 1)
                        {
                            String errMsg = String.Format("Invalid results returned.", 2);
                            LogEvent(errMsg);
                        }

                        if (ds.Tables[0].Rows[0]["BuildNumber"].ToString().Length > 0)
                        {
                            //Set up BuildInfo for the notification
                            buildInfo.BuildNumber = (String)ds.Tables[0].Rows[0]["BuildNumber"];
                            newCheckIn = true;
                            return true;
                        }
                        else
                        {
                            return false;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return false;
            }
        }

        //Send Email, log any errors
        private static void SendEmail(String messageAlias)
        {

            try
            {
                String mailErr = String.Empty;

                if (buildInfo != null)
                {
                    mailErr = mailSender.SendAbcMessage(messageAlias, buildInfo);
                }
                else
                {
                    mailErr = mailSender.SendAbcMessage(messageAlias);
                }

                if (mailErr.Length > 0)
                {
                    LogEvent(String.Format("Error sending email {0}: {1}", messageAlias, mailErr));
                }
                else
                {
                    LogInfoEvent(String.Format("{0} message sent.", messageAlias));
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }

        private static Boolean ExecuteCashValueCommand(String command)
        {
            LogEvent("Executing Build Compare [Cash Value]", 0);
            String retVal = String.Empty;
            try
            {
                System.Diagnostics.ProcessStartInfo procStartInfo =
                    new System.Diagnostics.ProcessStartInfo("cmd", "/c " + command);
                procStartInfo.RedirectStandardOutput = true;
                procStartInfo.UseShellExecute = false;
                procStartInfo.CreateNoWindow = true;
                System.Diagnostics.Process proc = new System.Diagnostics.Process();
                proc.StartInfo = procStartInfo;
                proc.Start();
                retVal = proc.StandardOutput.ReadToEnd();
                // Display the command output.
                if (retVal.Length > 0)
                {
                    LogEvent(String.Format("RETURNED FROM CASH VALUE: >>> {0} <<<", retVal), 1);
                    return false;
                }
                else
                {
                    LogEvent("NO RETURN DATA FROM CASH VALUE", FATAL);
                    return true;
                }

                Console.WriteLine(retVal);
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return false;
            }
        }

        //Bulk insert from ABC data files
        private static Boolean LoadDailyData(String loadPath, string machineName)
        {
            LogInfoEvent();

            try
            {
                using (SqlConnection con = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand cmd = new SqlCommand("Util.abc_BulkInsert", con))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandTimeout = 14400;
                        con.Open();
                        cmd.Parameters.AddWithValue("@loadPath", loadPath);
                        cmd.Parameters.AddWithValue("@runType", runType);
                        cmd.Parameters.AddWithValue("@machineName", machineName);
                        cmd.ExecuteNonQuery();
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return false;
            }
        }

        //Prepare data base to receive new current day records
        private static Boolean DailyReset()
        {
            LogInfoEvent();
            try
            {
                //Clear the ABC status directory
                if (Directory.Exists(abcStatusPath))
                {
                    Array.ForEach(Directory.GetFiles(abcStatusPath), File.Delete);
                }

                //Set up the BuildInfo
                SetBuildInfo();

                //Prepare ABC data tables
                using (SqlConnection con = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand cmd = new SqlCommand("Util.abc_DailyReset", con))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandTimeout = 2400;
                        cmd.Parameters.AddWithValue("@runType", runType);
                        con.Open();
                        cmd.ExecuteNonQuery();
                        return true;
                    }
                }
            }

            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return false;
            }
        }

        //Copies all files and subdirs in source directory to target directory
        private static void CopyOutputFiles(string sourceDir, string targetDir, Boolean deleteSourceFiles = false)
        {
            try
            {
                LogInfoEvent();

                if (deleteSourceFiles)
                {
                    LogEvent(String.Format("Moving files from: {0} to {1}", sourceDir, targetDir), 0);
                }
                else
                {
                    LogEvent(String.Format("Copying files from: {0} to {1}", sourceDir, targetDir), 0);
                }

                //Create target if necessary
                Directory.CreateDirectory(targetDir);

                //Clear any existing files
                Array.ForEach(Directory.GetFiles(targetDir), File.Delete);

                //Copy today's output files
                foreach (var file in Directory.GetFiles(sourceDir))
                    File.Copy(file, Path.Combine(targetDir, Path.GetFileName(file)), true);

                //If optional flag set, move vice copy 
                if (deleteSourceFiles)
                {
                    Array.ForEach(Directory.GetFiles(sourceDir), File.Delete);
                }

            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }

        private static void DoBuildCompare()
        {
            LogInfoEvent();
            ResetABCIndexes();
            String[] abcTables = { "PlaceHolder" };
            abcTables = GetAbcTableNames();

            foreach (string tableName in abcTables)
            {
                SetupTableVariance(tableName);
            }
        }

        
        //Returns a string array having list of enabled Abc Tables
        private static void ResetABCIndexes()
        {
            LogInfoEvent();
            try
            {
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("util.abc_RebuildABCTableIndexes ", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        sqlComm.CommandTimeout = 900;
                        conn.Open();
                        sqlComm.Parameters.AddWithValue("@runType", runType);
                        sqlComm.ExecuteNonQuery();
                        return;
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }


        //Returns a string array having list of enabled Abc Tables
        private static String[] GetAbcTableNames()
        {
            LogInfoEvent();

            List<string> retVal = new List<string>();
            try
            {
                DataSet ds = new DataSet("AbcTableNames");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetEnabledTableNames", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        sqlComm.Parameters.AddWithValue("@runType", runType);
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count == 0)
                        {
                            String errMsg = String.Format("Invalid results returned.", 2);
                            LogEvent(errMsg);
                        }

                        for (byte i = 0; i < ds.Tables[0].Rows.Count; i++)
                        {
                            switch (abcRunType)
                            {
                                case EnumAbcRunType.AbcCore:
                                    retVal.Add((((String)ds.Tables[0].Rows[i]["TableName"]).Replace("_BC", "").Replace("Util.", "")));
                                    break;
                                case EnumAbcRunType.Projection:
                                    retVal.Add((((String)ds.Tables[0].Rows[i]["TableName"]).Replace("_PAC", "").Replace("Util.", "")));
                                    break;
                            }
                        }

                        return retVal.ToArray();
                    }
                }

            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), FATAL);
                return retVal.ToArray();
            }
        }


        private static void SetupTableVariance(String tableName)
        {
            LogInfoEvent(String.Format("Executing SetupTableVariance for {0}", tableName));
            try
            {
                using (SqlConnection con = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand cmd = new SqlCommand("Util.abc_FindDailyVariance", con))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        //These can take a while
                        cmd.CommandTimeout = 7200;
                        con.Open();
                        cmd.Parameters.AddWithValue("@tableName", tableName);
                        cmd.Parameters.AddWithValue("@runType", runType);
                        cmd.ExecuteNonQuery();
                        return;
                    }
                }

            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }

        public static void LogEvent(String logMessage = "", Byte severity = 2)
        {
            //Get calling method
            StackTrace stackTrace = new StackTrace();
            String caller = stackTrace.GetFrame(1).GetMethod().Name;
            if (caller == "LogInfoEvent")
            {
                caller = stackTrace.GetFrame(2).GetMethod().Name;
            }

            //If no message passed, assume method entry
            if (logMessage.Length == 0)
            {
                logMessage = String.Format("{0} method called", caller);
            }

            if (severity == FATAL)
            {
                logMessage = ">>>>> RUN ABORTED: " + logMessage.ToUpper() + " <<<<<";
            }
            Console.WriteLine(logMessage);

            try
            {
                using (SqlConnection con = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand cmd = new SqlCommand("Util.abc_LogABCEvent", con))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        con.Open();
                        cmd.Parameters.AddWithValue("@Logger", caller);
                        cmd.Parameters.AddWithValue("@LogMessage", logMessage);
                        cmd.Parameters.AddWithValue("@Severity", severity);
                        cmd.Parameters.AddWithValue("@BuildNumber", buildInfo.BuildNumber ?? String.Empty);
                        cmd.Parameters.AddWithValue("@RunType", runType);
                        cmd.ExecuteNonQuery();

                        if (severity == FATAL)
                        {
                            Environment.Exit(1);
                        }
                        return;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Environment.Exit(1);
            }
        }

        public static void LogInfoEvent(String logMessage = "")
        {
            LogEvent(logMessage, 0);
        }

        private static void SetBuildInfo()
        {
            LogInfoEvent();
            try
            {
                DataSet ds = new DataSet("BuildInfo");

                using (TransactionScope tran = new TransactionScope())
                {
                    using (SqlConnection conn = new SqlConnection(abcDBConx))
                    {
                        using (SqlCommand sqlComm = new SqlCommand("Util.abc_NewBuildInfo", conn))
                        {
                            sqlComm.CommandType = CommandType.StoredProcedure;
                            sqlComm.CommandTimeout = 600;
                            sqlComm.Parameters.AddWithValue("@runType", runType);
                            SqlDataAdapter da = new SqlDataAdapter();
                            da.SelectCommand = sqlComm;
                            da.Fill(ds);

                            if (ds.Tables[0].Rows.Count != 1)
                            {
                                String errMsg = String.Format("Invalid results returned.", 2);
                                LogEvent(errMsg);
                            }

                            buildInfo.BuildId = (Int32)ds.Tables[0].Rows[0]["BuildId"];
                            buildInfo.BuildNumber = (String)ds.Tables[0].Rows[0]["BuildNumber"];
                            buildInfo.StartTime = (DateTime)ds.Tables[0].Rows[0]["BuildDateTime"];
                            buildInfo.PreviousBuildNumber = (String)ds.Tables[0].Rows[0]["PreviousBuildNumber"];
                        }
                    }
                    tran.Complete();
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), FATAL);
            }
        }

        public static void UpdateBuildInfo(Boolean errorCountOnly = false)
        {
            LogInfoEvent();
            try
            {

                DataSet ds = new DataSet("UpdateBuildInfo");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_UpdateBuildInfo", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        sqlComm.CommandTimeout = 600;
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        sqlComm.Parameters.AddWithValue("@BuildId", buildInfo.BuildId);
                        sqlComm.Parameters.AddWithValue("@runType", runType);
                        sqlComm.Parameters.AddWithValue("@errorCountOnly", @errorCountOnly);
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count != 1)
                        {
                            String errMsg = String.Format("Invalid results returned.", 2);
                            LogEvent(errMsg);
                        }

                        buildInfo.ErrorCount = (Int32)ds.Tables[0].Rows[0]["ErrorCount"];
                        buildInfo.DeltaCount = (Int32)ds.Tables[0].Rows[0]["DeltaCount"];
                        buildInfo.Delta = buildInfo.DeltaCount > 0;
                        buildInfo.ElapsedTime = DateTime.Now.Subtract(buildInfo.StartTime);
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }


        public static void ArchiveOutputFiles()
        {
            LogInfoEvent();
            try
            {
                DataSet ds = new DataSet("BuildVersionData");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetBuildVersions", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        sqlComm.Parameters.AddWithValue("@runType", runType);
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count > 1)
                        {
                            //ds.Tables[0].Rows[0] is the current run
                            //If not already existing, archive current version 
                            String priorDayArchivePath = Path.Combine(outputPath, ds.Tables[0].Rows[1]["BuildNumber"].ToString());
                            if (!Directory.Exists(priorDayArchivePath) && Directory.Exists(outputPath))
                            {
                                List<String> priorDayFileList = Directory.GetFiles(outputPath).ToList();
                                //Archive Output files and move to new folder
                                if (priorDayFileList.Count() > 0)
                                {
                                    Directory.CreateDirectory(priorDayArchivePath);
                                    SevenZipArchiver.CompressFiles(priorDayFileList, false, Path.Combine(priorDayArchivePath, ds.Tables[0].Rows[1]["BuildNumber"].ToString() + ".7z"),
                                        CompressionLevel.Fast);
                                }
                            }

                            //Clear prior day output files
                            Array.ForEach(Directory.GetFiles(outputPath), File.Delete);

                            //If > [ArchiveDataSets] rows delete previous versions
                            if (ds.Tables[0].Rows.Count > Properties.Settings.Default.ArchiveDataSets + 1)
                            {
                                for (int i = Properties.Settings.Default.ArchiveDataSets + 1; i < ds.Tables[0].Rows.Count; i++)
                                {
                                    //Delete Archive Folders
                                    String archiveToDelete = Path.Combine(outputPath,
                                        ds.Tables[0].Rows[i]["BuildNumber"].ToString());
                                    if (Directory.Exists(archiveToDelete))
                                    {
                                        //Empty the folder and delete 
                                        Array.ForEach(Directory.GetFiles(archiveToDelete), File.Delete);
                                        Directory.Delete(archiveToDelete);
                                    }
                                }
                            }
                        }
                        else
                        {
                            LogInfoEvent("There is nothing to Archive yet.");
                        }
                    }
                }

            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }


        /// <summary>
        /// Send a reminder note to users they have pending assignments.
        /// </summary>
        /// <param name=messageAlias </param>
        /// <returns></returns>
        private static void SendDeltaReminders()
        {
            LogInfoEvent();

            try
            {

                DataTable dt = new DataTable("DeltaReminder");
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetPendingAssignmentList", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(dt);
                    }

                    var dtEnumerable = dt.AsEnumerable();
                    List<DeltaAssignment> deltaAssignedPendingList = 
                        (from item in dtEnumerable
                            select new DeltaAssignment
                            {
                                BuildId = item.Field<Int32>("BuildId"),
                                BuildNumber = item.Field<String>("BuildNumber"),
                                BuildDateTime = item.Field<DateTime>("BuildDateTime"),
                                RunType = item.Field<String>("RunType"),
                                AssignmentId = item.Field<Int32>("DeltaAssignmentId"),
                                AssignedTo = item.Field<Int16>("AssignedTo"),
                                AssignmentStatus = item.Field<String>("AssignmentStatus"),
                                Baseline = item.Field<String>("Baseline"),
                                ChangeSetId = item.Field<Int32>("ChangeSetId"),
                                CheckInDate = item.Field<DateTime>("CheckInDate"),
                                SourceFile = item.Field<String>("SourceFile"),
                                TfsPath = item.Field<String>("TfsPath"),
                                ChangeType = item.Field<String>("ChangeType"),
                                Assignee = item.Field<String>("Assignee")

                            }
                        ).ToList();


                    deltaAssignedPendingList.Select(x => x.AssignedTo).Distinct().ToList().ForEach(s =>
                    {
                        string assignee = string.Empty;
                        string deltaMessage = string.Empty;
                        int recordCount = 0;
                        System.Text.StringBuilder sb = new System.Text.StringBuilder();
                        var assignmentList = deltaAssignedPendingList.Where(x => x.AssignedTo == s).ToList();

                        sb.Append("<table style='font-family:'Trebuchet MS', Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;'");
                        sb.AppendFormat("<tr ><th style='font-size:1.1em;text-align:center;padding-top:5px;padding-bottom:4px;background-color:lightblue;color:#fff;width:20%'>Build Number</th><th style='font-size:1.1em;text-align:center;padding-top:5px;padding-bottom:4px;background-color:lightblue;color:#fff;width:20%'>Change Set#</th><th style='font-size:1.1em;text-align:center;padding-top:5px;padding-bottom:4px;background-color:lightblue;color:#fff;width:20%'>Source File</th> <th style='font-size:1.1em;text-align:center;padding-top:5px;padding-bottom:4px;background-color:lightblue;color:#fff;width:20%'>Checkin Date </th>  <th style='font-size:1.1em;text-align:center;padding-top:5px;padding-bottom:4px;background-color:lightblue;color:#fff;width:20%'> Open Since </th> </tr>");
                        assignmentList.ForEach(assignment =>
                        {
                            if ((recordCount++ % 2) == 0)
                            {
                                sb.AppendFormat("<tr><td style='font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{0}</td><td style='font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%' >{1}</td><td style='font-size:1.0em;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{2}</td><td style='font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{3}</td><td style='font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{4}</td></tr>", assignment.BuildNumber.ToString(), assignment.ChangeSetId == 0 ? MESSAGE_FIELD_VALUE_NONE : assignment.ChangeSetId.ToString(), assignment.SourceFile.Length > 1 ? assignment.SourceFile : MESSAGE_FIELD_VALUE_NONE, DateTime.Compare(assignment.CheckInDate, new DateTime(1900, 01, 01)) > 0 ? assignment.CheckInDate.ToShortDateString() : MESSAGE_FIELD_VALUE_NONE, assignment.BuildDateTime.ToShortDateString());
                            }
                            else
                            {
                                sb.AppendFormat("<tr><td style='color:#000;background-color:#EAF2D3;font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{0}</td><td style='color:#000;background-color:#EAF2D3;font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%' >{1}</td><td style='color:#000;background-color:#EAF2D3;font-size:1.0em;border:1px solid gray;padding:3px 7px 2px 7px;width:20%' >{2}</td><td style='color:#000;background-color:#EAF2D3;font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{3}</td><td style='color:#000;background-color:#EAF2D3;font-size:1.0em;text-align:center;border:1px solid gray;padding:3px 7px 2px 7px;width:20%'>{4}</td></tr>", assignment.BuildNumber.ToString(), assignment.ChangeSetId == 0 ? MESSAGE_FIELD_VALUE_NONE : assignment.ChangeSetId.ToString(), assignment.SourceFile.Length > 1 ? assignment.SourceFile : MESSAGE_FIELD_VALUE_NONE, DateTime.Compare(assignment.CheckInDate, new DateTime(1900, 01, 01)) > 0 ? assignment.CheckInDate.ToShortDateString() : MESSAGE_FIELD_VALUE_NONE, assignment.BuildDateTime.ToShortDateString());
                            }
                            assignee = assignment.Assignee;
                        });
                        sb.Append("<table>");

                        String mailErr = mailSender.SendAbcMessage("DeltaReminder", buildInfo, (short)s, sb.ToString());
                        if (mailErr.Length > 0)
                        {
                            LogEvent(String.Format("Error sending email {0}: {1}", "DeltaReminder", mailErr), 2);
                        }
                        else
                        {
                            LogEvent(String.Format("{0} message sent to {1}. ", "DeltaReminder", assignee), 0);
                        }
                    });
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
            }
        }
    }
}
