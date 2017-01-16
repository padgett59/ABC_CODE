using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Reflection.Emit;
using System.Web;
using System.Web.WebPages;
using System.Web.Mvc;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.IO;
using System.Text;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Reflection;
using System.Data.Objects;
using System.Text.RegularExpressions;
using ABC.Web.Models;
using Abc_Notify;
using Microsoft.Ajax.Utilities;
using WebGrease.Css.Extensions;
using EnumAbcRunType = Prefix.DeclareWarehouse.EnumAbcRunType;

namespace ABC.Web.Controllers
{

    public class BuildCompareController : Controller
    {
        //changed data from RunSummary.cshtml
        [DataContract]
        public class BuildInfoDataChanged
        {
            [DataMember]
            public string buildInfoId { get; set; }
            [DataMember]
            public string dataChanged { get; set; }
        }

        //Array of changed BuildInfoData
        public class BuildInfoDataChangedArr
        {
            public BuildInfoDataChanged[] buildInfoDataChangedArr { get; set; }
        }

        private FunctionsContext abcSpContext = new FunctionsContext();
        private AbcDBContext abcDataGetter = new AbcDBContext();
        private Notify mailSender = new Notify(WebConfigurationManager.AppSettings["MailServer"].ToString(),
                                                WebConfigurationManager.AppSettings["TestRegion"].ToString(),
                                                WebConfigurationManager.AppSettings["AbcWebUrl"].ToString());
        private String region = String.Empty;
        private const string DEFAULT_RUN_TYPE_DISPLAY = "ALL";
        private const string  DEFAULT_DELTA_STATUS_DISPLAY = "[ALL]"; // Default -  ALL= 0 , shows all assignments regardless of their status. 
        private const string ASSIGNMENT_STATUS_NONE = "None";

        public ActionResult Index()
        {
            return RedirectToAction("RunSummary", "BuildCompare");
        }

        public ActionResult Login()
        {
            ViewBag.userIdList = abcDataGetter.NotifyRecipients.Select(u => u.EmailAddress.Replace("@nationwide.com", "")).ToList();
            return View("~/ABCWeb/Views/BuildCompare/Login.cshtml");
        }

        public ActionResult LoginSave(string userId)
        {
            String[] userVals = userId.Split('~');
            if (userVals.Length == 3)
            {
                //Save new user info to NotifyRecipients
                NotifyRecipient newRecipient = new NotifyRecipient();
                newRecipient.EmailAddress = userVals[0] + "@nationwide.com";
                newRecipient.FName = userVals[1];
                newRecipient.LName = userVals[2];
                abcDataGetter.NotifyRecipients.Add(newRecipient);
                abcDataGetter.SaveChanges();
            }

            //Set userId cookie
            HttpCookie cookie = new HttpCookie("ABCLoginId");
            cookie.Value = userVals[0];
            cookie.Expires = DateTime.MaxValue;
            this.ControllerContext.HttpContext.Response.Cookies.Add(cookie);

            return RedirectToAction("RunSummary", "BuildCompare");
        }

        //Entry Page
        public ActionResult RunSummary()
        {
            bool inSession = false;

            //Set session id based on cookie if existing
            if (this.ControllerContext.HttpContext.Request.Cookies.AllKeys.Contains("ABCLoginId"))
            {
                Session["AbcLoginId"] = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
            }

            try
            {
                inSession = Session["AbcLoginId"].ToString().Length > 0;
            }
            catch (Exception)
            {
                //Do nothing
            }

            if (!inSession)
            {
                return RedirectToAction("Login", "BuildCompare");
            }
            else
            {

                int abcNumOfRows = Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["AbcNumOfRows"].ToString());
                ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                ViewBag.recipientList = abcDataGetter.NotifyRecipients.ToList();
                List<DeltaStatus> deltaStatus=new List<DeltaStatus>();
                deltaStatus.Add(new DeltaStatus { DeltaStatusId=0, Status="[ALL]"});
                deltaStatus.AddRange(abcDataGetter.DeltaStatus.ToList());
                ViewBag.DeltaStatus = deltaStatus.ToList();
                ViewBag.UserRole = abcDataGetter.NotifyRecipients.ToList().FirstOrDefault(x => x.EmailAddress.ToLower() == (String)(ViewBag.UserId).ToLower() + "@nationwide.com").RoleId != null ?
                                   abcDataGetter.NotifyRecipients.ToList().FirstOrDefault(x => x.EmailAddress.ToLower() == (String)(ViewBag.UserId).ToLower() + "@nationwide.com").RoleId
                                  : (Int32)EnumAbcRole.None;

                var getBuildInfoSet = abcSpContext.Database.SqlQuery<BuildInfoList>("Util.abc_GetBuildInfoList").OrderByDescending(bi => bi.BuildNumber).Take(abcNumOfRows).ToList();
 
                if (Session["DeltaAssignmentPlusList"] == null)
                {
                    Session["DeltaAssignmentPlusList"] = abcSpContext.GetDeltaAssignments();
                }
                List<DeltaAssignmentPlus> deltaAssignmentSet = (List<DeltaAssignmentPlus>)Session["DeltaAssignmentPlusList"];

                //Associate Delta Assignments to the BuildInfo objects
                getBuildInfoSet.ForEach(bi =>
                {
                    bi.DeltaAssignments = new List<DeltaAssignmentPlus>();
                    deltaAssignmentSet.Where(da => da.BuildId == bi.BuildId && da.RunType == bi.RunType).ForEach(ds => bi.DeltaAssignments.Add(ds));
                });

                //Set up the region string
                try
                {
                    region =
                        (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace(
                            "Prefix", "")).Replace("_ABC", "");
                }
                catch (Exception)
                {
                    //Do Nothing
                }

                ViewBag.Region = region;
                ViewBag.RunTypeFilterFilter = DEFAULT_RUN_TYPE_DISPLAY;
                ViewBag.AbcNumOfRowsFilter = abcNumOfRows;
                ViewBag.PageSize = abcNumOfRows;
                ViewBag.StatusFilter = DEFAULT_DELTA_STATUS_DISPLAY;

                return View("~/ABCWeb/Views/BuildCompare/RunSummary.cshtml", getBuildInfoSet);
            }

        }

        [AcceptVerbs(HttpVerbs.Post)]
        public ActionResult RunSummarySearch(FormCollection formValues)
        {
            string runType;
            int abcNumOfRows;

            try
            {
                    runType = formValues["rbType"];
                    abcNumOfRows = Convert.ToInt32(formValues["rbRun"]);

                    var getBuildInfoSet = abcSpContext.Database.SqlQuery<BuildInfoList>("Util.abc_GetBuildInfoList").ToList();
             
                   // Filter run type
                    getBuildInfoSet = runType == "ABC" ? getBuildInfoSet.Where(x => x.RunType == runType).ToList()
                                                       : runType == "PAC" ? getBuildInfoSet.Where(x => x.RunType == runType).ToList()
                                                       : getBuildInfoSet.ToList();

                    Session["DeltaAssignmentPlusList"] = abcSpContext.GetDeltaAssignments(formValues["selectedStatus"]);
                    List<DeltaAssignmentPlus> deltaAssignmentSet = (List<DeltaAssignmentPlus>)Session["DeltaAssignmentPlusList"];

                   // Filter delta status
                    switch (formValues["selectedStatus"])
                    {
                        case DEFAULT_DELTA_STATUS_DISPLAY:
                            getBuildInfoSet = getBuildInfoSet.ToList();
                            break;
                        case ASSIGNMENT_STATUS_NONE:
                            getBuildInfoSet = getBuildInfoSet.Where(x => !deltaAssignmentSet.Select(b => b.BuildId).Contains(x.BuildId)).ToList();
                            break;
                        default:
                            getBuildInfoSet = getBuildInfoSet.Where(x => deltaAssignmentSet.Select(b => b.BuildId).Contains(x.BuildId)).ToList();
                            break;
                    } 
                   
                    //Associate Delta Assignments to the BuildInfo objects
                    getBuildInfoSet.ForEach(bi =>
                    {
                        bi.DeltaAssignments = new List<DeltaAssignmentPlus>();
                        deltaAssignmentSet.Where(da => da.BuildId == bi.BuildId && da.RunType == bi.RunType).ForEach(ds => bi.DeltaAssignments.Add(ds));
                    });

                   //Filter number of runs to display
                    getBuildInfoSet = abcNumOfRows != -1 ?
                                           getBuildInfoSet.OrderByDescending(bi => bi.BuildNumber).Take(abcNumOfRows).ToList()
                                          : getBuildInfoSet.OrderByDescending(bi => bi.BuildNumber).ToList();

                   
                   ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                   ViewBag.RunTypeFilter = runType;
                   ViewBag.AbcNumOfRowsFilter = abcNumOfRows;
                   ViewBag.recipientList = abcDataGetter.NotifyRecipients.ToList();
                   
                   List<DeltaStatus> deltaStatus = new List<DeltaStatus>();
                   deltaStatus.Add(new DeltaStatus { DeltaStatusId = 0, Status = "[ALL]" });
                   deltaStatus.AddRange(abcDataGetter.DeltaStatus.ToList());
                   ViewBag.DeltaStatus = deltaStatus.ToList();
                    
                   ViewBag.UserRole = abcDataGetter.NotifyRecipients.ToList().FirstOrDefault(x => x.EmailAddress == ViewBag.UserId + "@nationwide.com").RoleId != null ?
                                       abcDataGetter.NotifyRecipients.ToList().FirstOrDefault(x => x.EmailAddress == ViewBag.UserId + "@nationwide.com").RoleId
                                      : (Int32)EnumAbcRole.None;
                   
                   ViewBag.StatusFilter = Convert.ToString(formValues["selectedStatus"]);
                   ViewBag.PageSize = Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["AbcNumOfRows"].ToString());
                   
                   try
                    {
                        ViewBag.Region = (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace("Prefix", "")).Replace("_ABC", "");
                    }
                    catch (Exception ex) { }

                    return View("~/ABCWeb/Views/BuildCompare/RunSummary.cshtml", getBuildInfoSet);
          
            }
            catch (Exception ex)
            {
            }

            return RedirectToAction("Login", "BuildCompare");
        }

        [AcceptVerbs(HttpVerbs.Post)]
        public ActionResult RunSummarySave(FormCollection formValues)
        {
            const Byte STATUS_ASSIGNED = 2;
            const Byte STATUS_NONE = 8;
            String valuesChanged = formValues["changeData"];
            JavaScriptSerializer ser = new JavaScriptSerializer();
            var buildInfoDataChangedList = ser.Deserialize<dynamic>(valuesChanged);

            //Update data
            var buildInfoList = abcDataGetter.BuildInfo.ToList();
            var deltaAssignmentList = abcDataGetter.DeltaAssignments.ToList();

            Int32 buildId = 0;
            Int16 assignedTo = 0;
            Int32 deltaAssignmentId = 0;

            foreach (object nextO in buildInfoDataChangedList)
            {
                String[] changeVals = ((String)nextO).Split('~');
                switch (changeVals[0])
                {
                    //New Assignment
                    case "a":
                        String assignedList = changeVals[2];
                        List<String> assignments = assignedList.Split(',').ToList();
                        assignments.ForEach(a =>
                        {
                            DeltaAssignment da = new DeltaAssignment();
                            da.BuildId = int.Parse(changeVals[1]);
                            da.RunType = (buildInfoList.Where(bi => bi.BuildId == int.Parse(changeVals[1])).Single()).RunType;
                            da.AssignedTo = Int16.Parse(a);
                            da.DeltaStatusId = STATUS_ASSIGNED;
                            //NOTE: The stored procedure handles the mechanics of adding the DeltaAssignment is needed and adding the DeltaCheckIn record
                            this.abcSpContext.Database.ExecuteSqlCommand("exec Util.abc_InsertDeltaAssignment {0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}",
                                da.BuildId,
                                da.RunType,
                                0,
                                da.AssignedTo,
                                null,
                                null,
                                null,
                                null,
                                "[Manual Assignment]",
                                null,
                                da.DeltaStatusId
                            );
                        });


                        break;

                    //Status Change or New Comment
                    case "e":
                    case "s":
                    case "c":
                        List<String> changeAssignmentArgs = changeVals[1].Split(':').ToList();
                        buildId = Int32.Parse(changeAssignmentArgs[0]);
                        assignedTo = Int16.Parse(changeAssignmentArgs[1]);
                        deltaAssignmentId = Int16.Parse(changeAssignmentArgs[2]);
                        if (changeVals[0] == "s")
                        {
                            deltaAssignmentList.Single(de => de.BuildId == buildId && de.AssignedTo == assignedTo && de.DeltaAssignmentId == deltaAssignmentId).DeltaStatusId = Byte.Parse(changeVals[2]);
                        }
                        else if (changeVals[0] == "e")
                        {
                            deltaAssignmentList.Single(de => de.BuildId == buildId && de.AssignedTo == assignedTo && de.DeltaAssignmentId == deltaAssignmentId).AssignedTo = Byte.Parse(changeVals[2]);
                        }
                        else
                        {
                            if (changeVals[2].Length > 0)
                            {
                                String brkStr = deltaAssignmentList.Single(de => de.BuildId == buildId && de.AssignedTo == assignedTo && de.DeltaAssignmentId == deltaAssignmentId).Comments != null ? "<br//>" : String.Empty;
                                String userId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                                deltaAssignmentList.Single(de => de.BuildId == buildId && de.AssignedTo == assignedTo && de.DeltaAssignmentId == deltaAssignmentId).Comments += String.Format("{0} <span style=\"color:blue\">{1}:</span> {2}", brkStr, userId, changeVals[2]);
                            }
                        }
                        abcDataGetter.SaveChanges();
                        break;

                    // delete assignment
                    case "d":
                        changeAssignmentArgs = changeVals[1].Split(':').ToList();
                        buildId = Int32.Parse(changeAssignmentArgs[0]);
                        assignedTo = Int16.Parse(changeAssignmentArgs[1]);
                        deltaAssignmentId = Int16.Parse(changeAssignmentArgs[2]);
                        if (changeVals[0] == "d")
                        {
                            //NOTE: The sp handles the deleting of any associated DeltaCheckIn(s)
                            this.abcSpContext.Database.ExecuteSqlCommand("exec Util.abc_DeleteDeltaAssignment {0}", deltaAssignmentId);
                        }
                        break;
                }

                //Refresh Session DeltaAssignment List
                Session["DeltaAssignmentPlusList"] = abcSpContext.GetDeltaAssignments();

            }
            return RedirectToAction("RunSummary", "BuildCompare");
        }

        public ActionResult ViewBuildCheckIns(int runId)
        {
            ViewBag.BuildNumber = abcDataGetter.BuildInfo.FirstOrDefault(bi => bi.BuildId == runId).BuildNumber;
            List<BuildCheckIn> buildCheckInList = (List<BuildCheckIn>)(abcSpContext.Database.SqlQuery<BuildCheckIn>("Exec Util.abc_CheckinsByBuildId {0}", runId).OrderByDescending(ci => ci.DeltaAssigned).ToList());
            return View("~/ABCWeb/Views/BuildCompare/ViewBuildCheckins.cshtml", buildCheckInList);
        }

            private void SendAssignedEmail(BuildInfo bi)
        {
            if (mailSender.conxString == null || mailSender.conxString.Length == 0)
            {
                mailSender.conxString = ConfigurationManager.ConnectionStrings["AbcDBContext"].ConnectionString;
            }
            Notify.BuildInfo notifyBi = new Notify.BuildInfo();
            notifyBi.BuildId = bi.BuildId;
            notifyBi.BuildNumber = bi.BuildNumber;
            notifyBi.DeltaCount = (int)bi.DeltaCount;
            notifyBi.ErrorCount = (int)bi.ErrorCount;

            switch (bi.RunType)
            {
                case "B":
                    mailSender.abcRunType = EnumAbcRunType.AbcCore;
                    break;
                case "P":
                    mailSender.abcRunType = EnumAbcRunType.Projection;
                    break;
            }

            //String mailErr = mailSender.SendAbcMessage("DeltaAssigned", notifyBi, (short)bi.AssignedTo);
            //if (mailErr.Length > 0)
            //{
            //    LogEvent(bi, String.Format("Error sending email {0}: {1}", "DeltaAssigned", mailErr));
            //}
            //else
            //{
            //    LogEvent(bi, String.Format("{0} message sent.", "DeltaAssigned"), 0);
            //}

        }

        private void LogEvent(BuildInfo buildInfo, String logMessage = "", Byte severity = 2)
        {
            //Get calling method
            StackTrace stackTrace = new StackTrace();
            MethodBase methodBase = stackTrace.GetFrame(1).GetMethod();

            //If no message passed, assume method entry
            if (logMessage.Length == 0)
            {
                logMessage = String.Format("{0} method called", methodBase.Name);
            }

            this.abcSpContext.Database.ExecuteSqlCommand("exec Util.abc_LogABCEvent {0},{1},{2},{3}",
                "ABC.Web." + methodBase.Name, logMessage, severity, buildInfo.BuildNumber);

        }

        private String BreakAtCaps(String tableName)
        {
            char[] tableChars = tableName.ToCharArray();
            String outString = tableName.Substring(0, 6);
            for (int i = 6; i < tableName.Length; i++)
            {
                if (char.IsUpper(tableChars[i]) && char.IsLower(tableChars[i - 1]) || char.IsUpper(tableChars[i]) && char.IsNumber(tableChars[i - 1]))
                {
                    outString += "<br>" + tableChars[i];
                }
                else
                {
                    outString += tableChars[i];
                }
            }
            return outString;
        }

        public ActionResult VariantTables(int runId = 0)
        {
            //Get data
            List<BuildSummary> buildSummaryList = abcDataGetter.BuildSummary.Where(s => s.BuildId == runId).ToList();
            
            //Get requested buildInfo and the one prior
            var buildInfoAll = abcDataGetter.BuildInfo.OrderByDescending(bi => bi.BuildNumber);
            var buildInfoSet = buildInfoAll.Where(bi => bi.BuildId <= runId).Take(2).ToList();
            ViewBag.BuildInfo = buildInfoSet[0];

            //Is the build selected the current build?
            Boolean isCurrentBuild = buildInfoSet[0].BuildId == buildInfoAll.First().BuildId;

            String priorBuildNumber = String.Empty;
            if (buildInfoSet.Count > 1)
            {
               priorBuildNumber = buildInfoSet[1].BuildNumber;
            }

            String archivePath = ConfigurationManager.AppSettings["AbcArchivePath"].ToString();
            ViewBag.CurrentArchivePath = "";
            if (isCurrentBuild)
            {
                ViewBag.CurrentArchivePath = archivePath;
            }
            else if (Directory.Exists(archivePath + "\\\\" + ViewBag.BuildInfo.BuildNumber))
            {
                ViewBag.CurrentArchivePath = archivePath + "\\\\" + ViewBag.BuildInfo.BuildNumber;
            }

            ViewBag.PriorArchivePath = "";
            if (priorBuildNumber.Length > 0)
            {
                if (Directory.Exists(archivePath + "\\" + priorBuildNumber))
                {
                    ViewBag.PriorArchivePath = archivePath + "\\" + priorBuildNumber;
                }
            }

            ViewBag.TableNames = buildSummaryList.GroupBy(s => s.TableName).Select(grp => grp.First()).Select(s => s.TableName);
            List<String> tableNameList = new List<string>();

            foreach (String tableName in ViewBag.TableNames)
            {
                if (ViewBag.BuildInfo.RunType == "B")
                {
                    tableNameList.Add(BreakAtCaps(tableName));
                }
                else
                {
                    tableNameList.Add(tableName);
                }
            }
            ViewBag.TableNamesThin = tableNameList;
            ViewBag.RunId = runId;

            var Products = buildSummaryList.OrderBy(s => s.Product).GroupBy(s => s.Product).Select(grp => grp.First()).Select(s => s.Product);

            //For each product, determine the status for each data table
            IDictionary<Byte, IDictionary<String, Byte>> tableStatusByProduct = new ConcurrentDictionary<Byte, IDictionary<String, Byte>>();
            foreach (Byte product in Products)
            {
                IDictionary<String, Byte> tableRecord = new Dictionary<string, byte>();
                enumTableStatus recStatus = new enumTableStatus();
                var prodSummaryList = buildSummaryList.Where(s => s.Product == product).ToList();
                foreach (String table in ViewBag.TableNames)
                {

                    BuildSummary tableRec = prodSummaryList.Where(s => s.TableName == table).First();
                    if (tableRec.TotalRecords == null)
                    {
                        recStatus = enumTableStatus.NoRecords;
                    }
                    else if ((tableRec.TotalRecords > 0) && (tableRec.DiffRecords > 0))
                    {
                        recStatus = enumTableStatus.Variants;
                    }
                    else
                    {
                        recStatus = enumTableStatus.NoVariants;
                    }
                    tableRecord.Add(table, (Byte)recStatus);
                }
                tableStatusByProduct.Add(product, tableRecord);
            }
            //Since Dictionaries cannot be ordered, convert to an list
            var orderedTableStatusList = tableStatusByProduct.OrderBy(s => s.Key);
            //Change the type back to  Dictionary for use in the Model
            var orderedTableStatusDict = orderedTableStatusList.ToDictionary((keyItem) => keyItem.Key, (valueItem) => valueItem.Value);
            return View("~/ABCWeb/Views/BuildCompare/VariantTables.cshtml", orderedTableStatusDict);
        }

        [AcceptVerbs(HttpVerbs.Get)]
        public ActionResult ViewVariantRecords(String table = "", Byte product = 0, Int32 runId = 0, String policy = "", decimal amountFilter = 0)
        {

            string columnNames = string.Empty;

            ViewBag.Product = product;
            ViewBag.DataTable = table;
            ViewBag.RunId = runId;

            //Load BuildInfo 
            BuildInfo buildInfo = abcDataGetter.BuildInfo.Where(s => s.BuildId == runId).First();
            
            //If Var records have been removed, redirect to records removed page
            if (buildInfo.DeltasDeleted)
            {
                return View("~/ABCWeb/Views/BuildCompare/VariantRecordsRemoved.cshtml");
            }

            //Populates Variant and Unique record lists and columnNames (as delimited string)
            var varData = abcSpContext.GetVarData(table, product, runId, out columnNames, policy);

            if (amountFilter > 0)
            {
                int filteredCount = 0;
                List<PolicyCurrentPrior> filteredVarRecords = ApplyAmountFilter(columnNames, amountFilter, varData.Where(varRecLists => varRecLists.Key.Contains("V"))
                        .Select(varRecLists => varRecLists.Value).First(), out filteredCount);
                ViewBag.varRecords = filteredVarRecords;
                ViewBag.filteredCount = filteredCount;
            }
            else
            {
                ViewBag.varRecords = varData.Where(varRecLists => varRecLists.Key.Contains("V"))
                                .Select(varRecLists => varRecLists.Value).First();
                ViewBag.filteredCount = 0;
            }
            ViewBag.mmRecords = varData.Where(varRecLists => varRecLists.Key.Contains("U"))
                                .Select(varRecLists => varRecLists.Value).First();
            List<int> policyListVar = ((List<PolicyCurrentPrior>)ViewBag.varRecords).DistinctBy(cp => cp.Number).Select(rec => rec.Number).ToList();
            List<int> policyListUnique = ((List<PolicyCurrentPrior>)ViewBag.mmRecords).DistinctBy(cp => cp.Number).Select(rec => rec.Number).ToList();
            ViewBag.policyList = CombineLists(policyListVar, policyListUnique);

            // First time page is loaded, store all policy numbers in session to
            // use with the dropdown filter
            if (String.IsNullOrEmpty(policy))
            {
                Session["PolicyListAll"] = ViewBag.policyList;
            }
            ViewBag.policyListAll = Session["PolicyListAll"];

            ViewBag.columnHeaders = columnNames.Split('%').ToList();
            ViewBag.Policy = policy;
            ViewBag.AmountFilter = amountFilter;
            
            //To support code lookup mouseovers
            ViewBag.TransactionCodes = abcDataGetter.TransactionCodes.ToList();
            ViewBag.AmountCodes = abcDataGetter.AmountCodes.ToList();
            ViewBag.AttributeCodes = abcDataGetter.AttributeCodes.ToList();

            return View("~/ABCWeb/Views/BuildCompare/ViewVariantRecords.cshtml");
        }

        private List<PolicyCurrentPrior> ApplyAmountFilter(string columnNames, decimal amtDiffFilter, List<PolicyCurrentPrior> recList, out int filteredCount)
        {
            filteredCount = 0;
            List<PolicyCurrentPrior> retVal = new List<PolicyCurrentPrior>();
            //Find Amount Column Index
            Byte amtColIndex = (Byte)Array.IndexOf(columnNames.Split('%'),"Amount");

            if (amtColIndex == 255)
            {
                amtColIndex = (Byte)Array.IndexOf(columnNames.Split('%'), "Dollars");
            }

            if (amtColIndex != 255)
            {
                try
                {
                    //Return only records where the difference between the current amount and prior amount exceeds the amountDiffFilter
                    recList.ForEach(vr =>
                    {
                        if (Math.Abs(ParseAmount(vr.DataStringCurrent.Split('%')[amtColIndex]) - ParseAmount(vr.DataStringPrior.Split('%')[amtColIndex])) > amtDiffFilter)
                        {
                            retVal.Add(vr);
                        }
                        else
                        {
                        }
                    });

                    filteredCount = recList.Count - retVal.Count;
                    return retVal;
                }
                catch
                {
                    return recList;
                }
            }
            //else no filterable columns
            else 
            {
                return recList;
            }
        }

        private Decimal ParseAmount(String amtString)
        {
            Char[] parsedString = amtString.ToCharArray().Where(c => Char.IsDigit(c) || c == '-' || c == '.').ToArray();
            return Convert.ToDecimal(new String(parsedString));
        }

        private List<int> CombineLists(List<int> list1, List<int> list2)
        {
            List<int> retList = new List<int>(list2);
            list1.ForEach(l1 =>
            {
                if (!retList.Contains(l1))
                {
                    retList.Add(l1);
                }
            });
            return retList;
        }

        public ActionResult Administration()
        {
            try
            {
                if (this.ControllerContext.HttpContext.Request.Cookies.AllKeys.Contains("ABCLoginId"))
                {
                    ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                    try
                    {
                        ViewBag.Region = (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace("Prefix", "")).Replace("_ABC", "");
                    }
                    catch (Exception ex) { }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return View("~/ABCWeb/Views/BuildCompare/Administration.cshtml");
        }

        [HttpGet]
        public ActionResult RunLog()
        {
            RunLogSearch runLog = new RunLogSearch();
            List<Byte> Severity = new List<Byte>();
            string buildNumber = string.Empty;

            try
            {
                if (Request.Cookies["ABCLoginId"] != null)
                {
                    var buildInfo = abcDataGetter.BuildInfo.OrderByDescending(b => b.BuildId).ToList();
                    runLog.BuildInfoList = new List<SelectListItem>();
                    var slSelections = new SelectListItem();
                    buildInfo.Select(b=>b.BuildNumber).Distinct().ForEach(x =>
                        {
                            slSelections = new SelectListItem();
                            slSelections.Text = x;
                            slSelections.Value = x;
                            runLog.BuildInfoList.Add(slSelections);
                        }
                    );

                    // Set default values for filter..
                    runLog.RunLog = new List<RunLog>();
                    runLog.RunType = "B";
                    runLog.ChkInfo = false;
                    runLog.ChkWarn = false;
                    runLog.ChkFatal = true;
                    runLog.ChkError = true;
                    runLog.BuildNumber = runLog.BuildInfoList.FirstOrDefault().Text;

                    // Filter data
                    Severity.Add(runLog.ChkInfo == true ? (Byte)EnumLogMessage.Info : (Byte)EnumLogMessage.None);
                    Severity.Add(runLog.ChkWarn == true ? (Byte)EnumLogMessage.Warn : (Byte)EnumLogMessage.None);
                    Severity.Add(runLog.ChkFatal == true ? (Byte)EnumLogMessage.Fatal : (Byte)EnumLogMessage.None);
                    Severity.Add(runLog.ChkError == true ? (Byte)EnumLogMessage.Error : (Byte)EnumLogMessage.None);
                    Severity.RemoveAll(x => x == (Byte)EnumLogMessage.None);

                    if (Severity.Any())
                    {

                        runLog.RunLog = (from runlog in abcDataGetter.RunLog
                                               where Severity.Contains(runlog.Severity)
                                               select runlog).ToList();
                    }
                    else
                    {
                        runLog.RunLog = abcDataGetter.RunLog.ToList();
                    }

                    runLog.RunLog = runLog.RunLog.Where(x => x.BuildNumber == runLog.BuildNumber && x.RunType == runLog.RunType).ToList();
                    ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;

                    try
                    {
                        ViewBag.Region = (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace("Prefix", "")).Replace("_ABC", "");
                    }
                    catch (Exception ex) { }
                }
                else
                {
                    return RedirectToAction("Login", "BuildCompare");
                }

            }
            catch (Exception ex)
            {

            }

            return View("~/ABCWeb/Views/BuildCompare/RunLog.cshtml", runLog);
        }

        [HttpPost]
        public ActionResult RunLog(RunLogSearch runLog)
        {

            RunLogSearch runLogSearch = new RunLogSearch();
            List<Byte> Severity = new List<Byte>();

            try
            {
                if (Request.Cookies["ABCLoginId"] != null)
                {
                    runLogSearch.RunLog = new List<Models.RunLog>();

                    Severity.Add(runLog.ChkInfo == true ? (Byte)EnumLogMessage.Info : (Byte)EnumLogMessage.None);
                    Severity.Add(runLog.ChkWarn == true ? (Byte)EnumLogMessage.Warn : (Byte)EnumLogMessage.None);
                    Severity.Add(runLog.ChkFatal == true ? (Byte)EnumLogMessage.Fatal : (Byte)EnumLogMessage.None);
                    Severity.Add(runLog.ChkError == true ? (Byte)EnumLogMessage.Error : (Byte)EnumLogMessage.None);
                    Severity.RemoveAll(x => x == (Byte)EnumLogMessage.None);

                    if (Severity.Any())
                    {

                        runLogSearch.RunLog = (from runlog in abcDataGetter.RunLog
                                               where Severity.Contains(runlog.Severity)
                                               select runlog).ToList();
                    }
                    else
                    {
                        runLogSearch.RunLog = abcDataGetter.RunLog.ToList();
                    }

                    runLogSearch.RunLog = runLogSearch.RunLog.Where(x => x.BuildNumber == runLog.BuildNumber && x.RunType == runLog.RunType).ToList();
                    runLogSearch.RunType = runLog.RunType;
                    runLogSearch.ChkInfo = runLog.ChkInfo;
                    runLogSearch.ChkWarn = runLog.ChkWarn;
                    runLogSearch.ChkFatal = runLog.ChkFatal;
                    runLogSearch.ChkError = runLog.ChkError;

                    var buildInfo = abcDataGetter.BuildInfo.OrderByDescending(b => b.BuildId).ToList();
                    runLogSearch.BuildInfoList = new List<SelectListItem>();
                    var slSelections = new SelectListItem();
                    buildInfo.Select(b=>b.BuildNumber).Distinct().ForEach(x =>
                    {
                        slSelections = new SelectListItem();
                        slSelections.Text = x;
                        slSelections.Value = x;
                        runLogSearch.BuildInfoList.Add(slSelections);
                    }
                    );

                    ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                    try
                    {
                        ViewBag.Region = (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace("Prefix", "")).Replace("_ABC", "");
                    }
                    catch (Exception ex) { }

                }
                else
                {
                    return RedirectToAction("Login", "BuildCompare");
                }

            }
            catch (Exception ex)
            {

            }
            return View("~/ABCWeb/Views/BuildCompare/RunLog.cshtml", runLogSearch);

        }

        [HttpGet]
        public ActionResult UserGroups()
        {
            UserGroups userGroups = new UserGroups();

            try
            {
                if (Request.Cookies["ABCLoginId"] != null)
                {

                    var usersList = (from users in abcDataGetter.NotifyRecipients
                                     join groupMap in abcDataGetter.NotifyGroupMembers on users.RecipientId equals groupMap.RecipientId
                                     select new { FirstName = users.FName, LastName = users.LName, UserId = users.RecipientId, GroupId = groupMap.GroupId }).ToList();

                    var groupList = abcDataGetter.NotifyGroups.ToList();
                    userGroups.GroupMemberInfo = new List<GroupMemberInfo>();

                    groupList.ForEach(g =>
                    {
                        usersList.Where(u => u.GroupId == g.GroupId).ForEach(x =>
                        {
                            GroupMemberInfo notifyGroupInfo = new GroupMemberInfo();
                            notifyGroupInfo.GroupId = x.GroupId;
                            notifyGroupInfo.GroupName = g.GroupName;
                            notifyGroupInfo.UserId = x.UserId;
                            notifyGroupInfo.UserGroupIds = x.UserId + "|" + x.GroupId;
                            notifyGroupInfo.UserName = x.FirstName + " " + x.LastName;
                            userGroups.GroupMemberInfo.Add(notifyGroupInfo);

                        });
                    });

                    ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                    try
                    {
                        ViewBag.Region = (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace("Prefix", "")).Replace("_ABC", "");
                    }
                    catch (Exception ex) { }
                }
                else
                {
                    return RedirectToAction("Login", "BuildCompare");
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }

            return View("~/ABCWeb/Views/BuildCompare/UserGroups.cshtml", userGroups);
        }

        [HttpPost]
        public ActionResult UserGroups(UserGroups model, FormCollection frmCollections)
        {

            try
            {
                if (Request.Cookies["ABCLoginId"] != null)
                {
                    JavaScriptSerializer serializer = new JavaScriptSerializer();
                    dynamic selectedGroupItem = serializer.Deserialize<object>(frmCollections["SelectedGroup"]);
                    string selectedGroup = selectedGroupItem[0];
                    List<SelectListItem> lst = new List<SelectListItem>();

                    model.SelectedUsers.ForEach(x =>
                    {
                        string[] selValues = x.Split('|');
                        lst.Add(new SelectListItem { Text = selValues[0], Value = selValues[1] });
                    });

                    lst.Where(x => x.Value == selectedGroup).ForEach(x =>
                    {
                        Byte groupId = Convert.ToByte(x.Value);
                        Int16 recipientId = Convert.ToInt16(x.Text);
                        var groupMap = abcDataGetter.NotifyGroupMembers.FirstOrDefault(n => n.GroupId == groupId && n.RecipientId == recipientId);
                        abcDataGetter.NotifyGroupMembers.Remove(groupMap);

                    });

                    abcDataGetter.SaveChanges();

                    ViewBag.UserId = this.ControllerContext.HttpContext.Request.Cookies["ABCLoginId"].Value;
                    try
                    {
                        ViewBag.Region = (((((System.Data.Entity.DbContext)(abcDataGetter)).Database.Connection).Database).Replace("Prefix", "")).Replace("_ABC", "");
                    }
                    catch (Exception ex) { }
                }
                else
                {
                    return RedirectToAction("Login", "BuildCompare");
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return RedirectToAction("UserGroups", "BuildCompare");
        }

        [HttpGet]
        public ActionResult AddGroupMember(Byte GroupId)
        {
            UserGroups userGroup = new UserGroups();

            try
            {
                if (Request.Cookies["ABCLoginId"] != null)
                {
                    var usersList = (from users in abcDataGetter.NotifyRecipients
                                     join groupMap in abcDataGetter.NotifyGroupMembers.Where(x => x.GroupId == GroupId) on users.RecipientId equals groupMap.RecipientId
                                     into groupMaps
                                     from map in groupMaps.DefaultIfEmpty()
                                     where map == null
                                     select new { FirstName = users.FName, LastName = users.LName, UserId = users.RecipientId }).Distinct();

                    ViewBag.GroupId = GroupId;
                    Session["GroupId"] = GroupId;
                    ViewBag.GroupName = abcDataGetter.NotifyGroups.FirstOrDefault(x => x.GroupId == GroupId).GroupName;

                    userGroup.GroupMemberInfo = new List<GroupMemberInfo>();
                    usersList.ForEach(x =>
                    {
                        GroupMemberInfo groupMemberInfo = new GroupMemberInfo();
                        groupMemberInfo.GroupId = GroupId;
                        groupMemberInfo.GroupName = ViewBag.GroupName;
                        groupMemberInfo.UserId = x.UserId;
                        groupMemberInfo.UserGroupIds = x.UserId.ToString();
                        groupMemberInfo.UserName = x.FirstName + " " + x.LastName;
                        userGroup.GroupMemberInfo.Add(groupMemberInfo);
                    });

                    if (userGroup.GroupMemberInfo.Count == 0)
                    {
                        userGroup.GroupMemberInfo.Add(new GroupMemberInfo { GroupId = 0, GroupName = "", UserGroupIds = "[None]", UserId = 0, UserName = "[None]" });
                    }

                    ViewData["ShouldClose"] = false;
                }
                else
                {
                    return RedirectToAction("Login", "BuildCompare");
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return View("~/ABCWeb/Views/BuildCompare/AddGroupMember.cshtml", userGroup);
        }

        [HttpPost]
        public ActionResult AddGroupMember(string GroupId, string selectedUsers)
        {
            try
            {
                if (Request.Cookies["ABCLoginId"] != null)
                {
                    selectedUsers.Split(',').ForEach(x =>
                    {
                        Int16 recipientId = Convert.ToInt16(x);
                        NotifyGroupMembers notifyGroupMember = new NotifyGroupMembers();
                        notifyGroupMember.GroupId = Convert.ToByte(GroupId);
                        notifyGroupMember.RecipientId = recipientId;
                        abcDataGetter.NotifyGroupMembers.Add(notifyGroupMember);
                    });

                    abcDataGetter.SaveChanges();
                    return Json(GroupId, "application/json", System.Text.Encoding.UTF8, JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return RedirectToAction("Login", "BuildCompare");
        }

        public ActionResult CheckInDetail(Int32 deltaAssignmentId, string buildNumber, string userName)
        {
            ViewBag.BuildNumber = buildNumber;
            ViewBag.UserName = userName;
            List<DeltaAssignmentPlus> deltaAssignmentSet = (List<DeltaAssignmentPlus>)Session["DeltaAssignmentPlusList"];
            DeltaAssignmentPlus deltaAssignment = deltaAssignmentSet.FirstOrDefault(da => da.DeltaAssignmentId == deltaAssignmentId);
            return View("~/ABCWeb/Views/BuildCompare/CheckInDetail.cshtml", deltaAssignment);
        }

        
    }

}
