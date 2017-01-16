using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

using Microsoft.TeamFoundation.VersionControl.Client;


using Prefix;
using EnumAbcRunType = Prefix.DeclareWarehouse.EnumAbcRunType;

namespace AutomatedBuild
{
    /// <summary>
    /// Executes an Automated Build Compare run type depending on command line parameter "Task"
    /// Task 97: BuildBcp (ABC)
    /// Task 98: Projections (PAC)
    /// </summary>
    public static partial class RunABC
    {
        //Set up Public Variables
        private static PublicVariables pv = new PublicVariables();
        private static String outputPath = String.Empty;
        private static String runType = String.Empty;
        private static String abcDBConx = String.Empty;
        private static Boolean newCheckIn = false;
        private static EnumAbcRunType abcRunType;

        //Delta Assignment Constants
        const Byte STATUS_ASSIGNED = 2;
        const Byte STATUS_NONE = 8;

        //Log severity 3 = Fatal Error
        private const byte FATAL = 3;
        private const string MESSAGE_FIELD_VALUE_NONE = "[none]";

        private class RunControlItem : IEquatable<RunControlItem>
        {
            public RunControlItem(String sourceType, String value)
            {
                this.SourceType = sourceType;
                this.Value = value;
            }
            public String SourceType { get; set; }
            public String Value { get; set; }

            //Override the Equals method for equatability by value (rather than reference)
            public bool Equals(RunControlItem testRunControlItem)
            {
                return (testRunControlItem.SourceType == this.SourceType) && (testRunControlItem.Value == this.Value);
            }
        }
        private static List<RunControlItem> runControlItemList = new List<RunControlItem>();

        private class PolicyProjection
        {
            public PolicyProjection(Int32 number, Int16 trxCode)
            {
                this.Number = number;
                this.TrxCode = trxCode;
            }
            Int32 Number { get; set; }
            Int16 TrxCode { get; set; }
        }

        private class CheckinItem
        {
            public CheckinItem(Int32 changeSetId, String developer, String firstName, String lastName, String sourceFile, String baseline, String tfsPath, ChangeType changeType, DateTime checkinDate)
            {
                this.ChangeSetId = changeSetId;
                this.Developer = developer;
                this.FName = firstName;
                this.LName = lastName;
                this.SourceFile = sourceFile;
                this.Baseline = baseline;
                this.TfsPath = tfsPath;
                this.ChangeType = changeType;
                this.CheckinDate = checkinDate;
            }
            public Int32 ChangeSetId { get; set; }
            public String Developer { get; set; }
            public String FName { get; set; }
            public String LName { get; set; }
            public String SourceFile { get; set; }
            public String Baseline { get; set; }
            public String TfsPath { get; set; }
            public ChangeType ChangeType { get; set; }
            public DateTime CheckinDate { get; set; }

        }

        private class PolicyFileInfo
        {
            public PolicyFileInfo (Int32 number, String fileName)
            {
                this.Number = number;
                this.FileName = fileName;
            }
            public Int32 Number { get; set; }
            public String FileName { get; set; }
        }

        private class DeltaAssignment
        {
            public Int32 BuildId { get; set; }
            public string BuildNumber { get; set; }
            public DateTime BuildDateTime { get; set; }
            public string RunType { get; set; }
            public Int32 AssignmentId { get; set; }
            public Int32 AssignedTo { get; set; }
            public string Baseline { get; set; }
            public Int32 ChangeSetId { get; set; }
            public string ChangeType { get; set; }
            public DateTime CheckInDate { get; set; }
            public string SourceFile { get; set; }
            public string TfsPath { get; set; }
            public string AssignmentStatus { get; set; }
            public String Assignee { get; set; }

        }
    }
}
