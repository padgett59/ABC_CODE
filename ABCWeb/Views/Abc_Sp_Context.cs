using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity.Migrations.Model;
using System.Linq;
using System.Reflection.Emit;
using System.Web;
using System.Data.Entity;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.Composition;
using System.ComponentModel.Design;
using System.Data.Linq.Mapping;
using System.Data.SqlClient;
using System.Web.Profile;
using System.Text.RegularExpressions;
using System.Web.Mvc;

namespace ABC.Web.Models
{

    public class BaseContext<TContext> : DbContext where TContext : DbContext
    {
        static BaseContext()
        {
            Database.SetInitializer<TContext>(null);
        }

        protected BaseContext()
            : base("name = AbcDBContext")
        { }
    }

    //Stored Procedure results
    public class FunctionsContext : BaseContext<FunctionsContext>
    {
        enum EnumVarDataType
        {
            Variant,
            Unique
        };

        private AbcDBContext abcDataGetter = new AbcDBContext();
        private List<AmtCode> AmountCodeList = new List<AmtCode>();
        private const String EXCLUDE_COLUMNS = "Run|Build|DiffType|Product";

        public FunctionsContext()
        {
            //Static List of Amount Codes
            this.AmountCodeList = abcDataGetter.AmountCodes.ToList();
        }

        //GetVarData varying # of columns in variance tables and populates Variant and Unique record lists
        public List<KeyValuePair<string, List<PolicyCurrentPrior>>> GetVarData(String table, Byte product, Int32 runId, out String columnNames, String policy = "")
        //public List<KeyValuePair<string, List<VarDataRecord>>> GetVarData(String table, Byte product, Int32 runId)
        {
            //initialize return object
            List<KeyValuePair<string, List<PolicyCurrentPrior>>> retVal = new List<KeyValuePair<string, List<PolicyCurrentPrior>>>();

            List<VarDataRecord> varDataRecords = new List<VarDataRecord>();
            List<PolicyCurrentPrior> varCPList = new List<PolicyCurrentPrior>();
            varDataRecords = AdoGetVarData(table, product, runId, EnumVarDataType.Variant, out columnNames, policy);

            var arrVarRecords = varDataRecords.ToArray();

            //Asssemble into current/prior records and highlight fields varying
            for (int i = 0; i < arrVarRecords.Count(); i += 2)
            {
                //Populate next C/P record
                PolicyCurrentPrior varRecordCurrentPrior = new PolicyCurrentPrior();
                varRecordCurrentPrior.Number = arrVarRecords[i].Number;
                varRecordCurrentPrior.DataStringCurrent = arrVarRecords[i].DataString;
                varRecordCurrentPrior.DataStringPrior = arrVarRecords[i + 1].DataString;
                HighLightFieldDiffs(ref varRecordCurrentPrior);
                varCPList.Add(varRecordCurrentPrior);
            }
            retVal.Add(new KeyValuePair<string, List<PolicyCurrentPrior>>("V", varCPList));


            ////**************MISMATCHED*************************************
            List<PolicyCurrentPrior> mmCPList = new List<PolicyCurrentPrior>();
            var mmRecList = AdoGetVarData(table, product, runId, EnumVarDataType.Unique, out columnNames, policy);

            mmRecList.ForEach(ur =>
            {
                PolicyCurrentPrior mmRecordCurrentPrior = new PolicyCurrentPrior();
                mmRecordCurrentPrior.Number = ur.Number;
                if (ur.Run == "C")
                {
                    mmRecordCurrentPrior.DataStringCurrent = ur.DataString;
                }
                else
                {
                    mmRecordCurrentPrior.DataStringPrior = ur.DataString;
                }
                mmCPList.Add(mmRecordCurrentPrior);
            });
            retVal.Add(new KeyValuePair<string, List<PolicyCurrentPrior>>("U", mmCPList));
            return retVal;
        }

        public List<DeltaAssignmentPlus> GetDeltaAssignments(string deltaStatus = "[ALL]")
        {
            List<DeltaCheckIn> checkIns = abcDataGetter.DeltaCheckIns.ToList();
            List<DeltaAssignmentPlus> retVal = ((deltaStatus == "[ALL]") || (deltaStatus == "None")) ? 
                this.Database.SqlQuery<DeltaAssignmentPlus>("Util.abc_GetDeltaAssignmentList").ToList()
                : this.Database.SqlQuery<DeltaAssignmentPlus>("Util.abc_GetDeltaAssignmentList").Where(x => x.Status == deltaStatus).ToList();
            //Associate the checkin lists to their Deltas
            retVal.ForEach(da =>
            {
                da.DeltaCheckInList = checkIns.Where(ci => ci.DeltaAssignmentId == da.DeltaAssignmentId).ToList();
            });
            return retVal;
        }

        //Gets the Variant Records by table, product#, runId, variation type (variant or unique)
        private List<VarDataRecord> AdoGetVarData(String table, Byte product, Int32 runId, EnumVarDataType type, out String columnNames, String policy = "")
        {

            List<VarDataRecord> varDataRecords = new List<VarDataRecord>();

            //Get the matched Records
            SqlDataReader dataReader;
            String wareHouseConx =
                System.Configuration.ConfigurationManager.ConnectionStrings["AbcDBContext"].ConnectionString;

            using (SqlConnection conx = new SqlConnection(wareHouseConx))
            {
                SqlCommand cmd = conx.CreateCommand();
                switch (type)
                {
                    case EnumVarDataType.Variant:
                        cmd.CommandText = "Util.abc_GetMatchedVariantRecords";
                        break;
                    case EnumVarDataType.Unique:
                        cmd.CommandText = "Util.abc_GetUniqueRecords";
                        break;
                }

                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@tableAlias", table.Replace("Util.", ""));
                cmd.Parameters.AddWithValue("@product", product);
                cmd.Parameters.AddWithValue("@buildId", runId);
                if (policy.Length > 0)
                {
                    cmd.Parameters.AddWithValue("@returnRowCount", -1);
                    cmd.Parameters.AddWithValue("@policy", policy);
                }
                conx.Open();
                dataReader = cmd.ExecuteReader();
                columnNames = GetColumnNames(dataReader);
                while (dataReader.Read())
                {
                    VarDataRecord newRecord = new VarDataRecord();
                    newRecord.Number = dataReader.GetInt32(dataReader.GetOrdinal("Number"));
                    newRecord.Run = dataReader.GetString(dataReader.GetOrdinal("Run"));
                    newRecord.DiffType = dataReader.GetString(dataReader.GetOrdinal("DiffType"));
                    newRecord.DataString = GetDataString(dataReader);
                    varDataRecords.Add(newRecord);
                }
            }
            return varDataRecords;
        }

        private Int16 FieldVarCount(VarDataRecord current, VarDataRecord prior)
        {
            Int16 retVal = 0;
            String[] cFields = current.DataString.Split('%');
            String[] pFields = prior.DataString.Split('%');
            for (Byte i = 0; i < cFields.Count(); i++)
            {
                if (cFields[i] != pFields[i])
                {
                    retVal++;
                }
            }
            return retVal;
        }

        //Highlights unqual fields in diff records
        private void HighLightFieldDiffs(ref PolicyCurrentPrior cpRec)
        {
            String[] currentVals = cpRec.DataStringCurrent.Split('%');
            String[] priorVals = cpRec.DataStringPrior.Split('%');
            String hlCurrent = String.Empty;
            String hlPrior = String.Empty;

            for (int i = 0; i < currentVals.Length; i++)
            {
                if (currentVals[i] != priorVals[i])
                {
                    hlCurrent += "<span style=\"color:red\">" + currentVals[i] + "</span>%";
                    hlPrior += "<span style=\"color:red\">" + priorVals[i] + "</span>%";
                }
                else
                {
                    hlCurrent += currentVals[i] + "%";
                    hlPrior += priorVals[i] + "%";
                }
            }
            cpRec.DataStringCurrent = (hlCurrent.Substring(0, hlCurrent.Length - 1));
            cpRec.DataStringPrior = (hlPrior.Substring(0, hlPrior.Length - 1));
        }

        //Creates the DataStrings for var records from the data reader row(s)
        private String GetDataString(SqlDataReader reader)
        {
            String retVal = String.Empty;

            //Read through the files for the row and compile the data as % delimited string
            Regex regexExp = new Regex(EXCLUDE_COLUMNS);

            for (int i = 0; i < reader.FieldCount; i++)
            {
                if (!regexExp.IsMatch(reader.GetName(i)))
                {
                    retVal += reader[i].ToString().Replace("12:00:00 AM", "") + "%";
                }
            }
            return retVal.Substring(0, retVal.Length - 1);
        }

        //Gets the for column names from the data reader 
        private String GetColumnNames(SqlDataReader reader)
        {
            String retVal = String.Empty;

            //Read through the files for the row and compile the data as % delimited string
            Regex regexExp = new Regex(EXCLUDE_COLUMNS);

            for (int i = 0; i < reader.FieldCount; i++)
            {
                if (!regexExp.IsMatch(reader.GetName(i)))
                {
                    retVal += reader.GetName(i).ToString() + "%";
                }
            }
            return retVal.Substring(0, retVal.Length - 1);
        }

        //Adds AmountCode name to data string based on amtCode field
        private String LookupAmountCode(String amtCode)
        {
            AmtCode foundCode = this.AmountCodeList.Where(ac => ac.AmountCode == Int16.Parse(amtCode)).FirstOrDefault();
            if (null == foundCode)
            {
                return String.Format("{0} ({1})", "Not Found", amtCode);
            }
            else
            {
                return String.Format("{0} ({1})", foundCode.AmountName ?? "Not Found", amtCode);
            }
        }


    }

    public class BuildCheckIn
    {
        public Boolean DeltaAssigned { get; set; }
        public String Developer { get; set; }
        public String SourceFile { get; set; }
        public String Path { get; set; }
        public String ChangeType { get; set; }
        public DateTime? CheckinDate { get; set; }
        public String Release { get; set; }
        public Int32? ChangeSetId { get; set; }
    }

    public class DeltaAssignmentPlus
    {
        public Int32 BuildId { get; set; }
        public String RunType { get; set; }
        public String Name { get; set; }
        public Int16 AssignedTo { get; set; }
        public Byte DeltaStatusId { get; set; }
        public String Status { get; set; }
        public String Comments { get; set; }
        [Key]
        public Int32 DeltaAssignmentId { get; set; }
        public Int32 AssignmentCheckInCount { get; set; }
        public List<DeltaCheckIn> DeltaCheckInList { get; set; }
    }

    public class DeltaAssignment
    {
        public Int32 BuildId { get; set; }
        public String RunType { get; set; }
        public Int16 AssignedTo { get; set; }
        public Byte DeltaStatusId { get; set; }
        public String Comments { get; set; }
        [Key]
        public Int32 DeltaAssignmentId { get; set; }
        public List<DeltaCheckIn> DeltaCheckInList { get; set; }
    }

    public class DeltaCheckIn
    {
        [Key]
        public Int32 DeltaCheckInId { get; set; }
        public Int32 DeltaAssignmentId { get; set; }
        public String Baseline { get; set; }
        public Int32? ChangeSetId { get; set; }
        public String ChangeType { get; set; }
        public DateTime? CheckinDate { get; set; }
        public String SourceFile { get; set; }
        public String TfsPath { get; set; }
    }

    public class BuildInfoList
    {
        [Key]
        public Int32 BuildId { get; set; }
        public String BuildNumber { get; set; }
        public String RunType { get; set; }
        public DateTime BuildDateTime { get; set; }
        public Int32? ErrorCount { get; set; }
        public Boolean? Deltas { get; set; }
        public Int32? DeltaCount { get; set; }
        public List<DeltaAssignmentPlus> DeltaAssignments { get; set; }
    }


    public class VarDataRecord
    {
        public Int32 Number { get; set; }
        public String DataString { get; set; }
        public String Run { get; set; }
        public String DiffType { get; set; }
    }

    public class PolicyCurrentPrior
    {
        public Int32 Number { get; set; }
        public String DataStringCurrent { get; set; }
        public String DataStringPrior { get; set; }
    }

    public class GroupMemberInfo
    {
        public byte GroupId { get; set; }
        public string GroupName { get; set; }
        public Int16 UserId { get; set; }
        public string UserName { get; set; }
        public string UserGroupIds { get; set; }
    }

    public class UserGroups
    {
        public List<GroupMemberInfo> GroupMemberInfo { get; set; }
        public string[] SelectedUsers { get; set; }

    }

    public class RunLogSearch
    {
        public List<RunLog> RunLog { get; set; }
        public List<SelectListItem> BuildInfoList { get; set; }
        public string BuildNumber { get; set; }
        public string RunType { get; set; }
        public bool ChkInfo { get; set; }
        public bool ChkWarn { get; set; }
        public bool ChkFatal { get; set; }
        public bool ChkError { get; set; }
    }

    public enum EnumAbcRole
    {
        None = 0,
        Admin = 1,
        TechLead = 2,
    }

    public enum EnumLogMessage
    {
        Info = 0,
        Warn = 1,
        Error = 2,
        Fatal = 3,
        None = 4
    }

}