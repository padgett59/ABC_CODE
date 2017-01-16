
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;

using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Client;
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


        /// <summary>
        /// Gets the changesets which have resulted in the given changeset due
        /// to a merge operation.
        /// </summary>
        /// <param name="changeset">The changeset.</param>
        /// <param name="versionControlServer">The version control server.</param>
        /// <returns>
        /// A list of all changesets that have resulted into the given changeset.
        /// </returns>
        private static List<CheckinItem> GetMergedChanges(Changeset changeset, VersionControlServer versionControlServer)
        {

            List<CheckinItem> mergeRootChanges = new List<CheckinItem>();

            // remember the already covered changeset id's
            Dictionary<int, bool> alreadyCoveredChangesets = new Dictionary<int, bool>();

            // initialize list of parent changesets
            List<Changeset> parentChangesets = new List<Changeset>();

            // go through each change inside the changeset
            foreach (Change change in changeset.Changes)
            {
                // query for the items' history
                var queryResults = versionControlServer.QueryMergesExtended(
                                        new ItemSpec(change.Item.ServerItem, RecursionType.Full),
                                        new ChangesetVersionSpec(changeset.ChangesetId),
                                        null,
                                        null);

                // go through each changeset in the history
                foreach (var result in queryResults)
                {
                    // only if the target-change is the given changeset, we have a hit
                    if (result.TargetChangeset.ChangesetId == changeset.ChangesetId)
                    {
                        // if that hit has already been processed elsewhere, then just skip it
                        if (!alreadyCoveredChangesets.ContainsKey(result.SourceChangeset.ChangesetId))
                        {
                            // otherwise add it
                            alreadyCoveredChangesets.Add(result.SourceChangeset.ChangesetId, true);
                            parentChangesets.Add(versionControlServer.GetChangeset(result.SourceChangeset.ChangesetId));
                        }
                    }
                }
            }

            //Drill down to replace merge sets with constituent changes
            parentChangesets.ForEach(s =>
            {
                if (!IsMergeSet(s))
                {
                    //Add changes to return set
                    s.Changes.ToList().ForEach(c => mergeRootChanges.Add(
                        new CheckinItem(
                            s.ChangesetId,
                            s.Owner.Replace("NWIE\\", ""),
                            s.OwnerDisplayName.Substring(0, s.OwnerDisplayName.IndexOf(" ")),
                            s.OwnerDisplayName.Substring(s.OwnerDisplayName.IndexOf(" ") + 1),
                            GetSourceFile(c.Item.ServerItem),
                            GetBaseline(c.Item.ServerItem),
                            GetTfsPath(c.Item.ServerItem),
                            c.ChangeType, c.Item.CheckinDate))
                            );
                }
                else
                {
                    //Recurse to next level to get to root changes
                    GetMergedChanges(s, versionControlServer).ForEach(ci => mergeRootChanges.Add(ci));
                }
            }
                );

            return mergeRootChanges;
        }

        //Determine if the change set is a merge set
        private static Boolean IsMergeSet(Changeset cSet)
        {
            return cSet.Comment.Contains("INTEGRATION MERGE[ACROSS]:");
        }

        //Get the file name from the server item
        private static String GetSourceFile(String serverItem)
        {
            return serverItem.Substring(serverItem.LastIndexOf("/") + 1);
        }

        //Get the Baseline from the server item
        private static String GetBaseline(String serverItem)
        {
            string retVal = serverItem.Replace("$/Prefix/DEV/", "");
            return "$/Prefix/DEV/" + retVal.Substring(0, retVal.IndexOf("/"));
        }

        //Get the tfsPath from the server item
        private static String GetTfsPath(String serverItem)
        {
            String retVal = serverItem.Replace(serverItem.Substring(serverItem.LastIndexOf("/") + 1), "");
            return retVal.Replace("/", "\\");
        }

        public static void AutoAssignDeltas(Boolean runDeltas)
        {
            LogInfoEvent();
            try
            {
                //Declare TFS Objects
                IBuildServer BuildServer;
                TfsTeamProjectCollection TfsServer;
                VersionControlServer VcServer;

                //Initialize TFS objects
                TfsServer = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(new Uri(Properties.Settings.Default.TfsServerUrl));
                TfsServer.Authenticate();
                VcServer = TfsServer.GetService<VersionControlServer>();
                BuildServer = TfsServer.GetService<IBuildServer>();

                List<CheckinItem> buildCheckins = new List<CheckinItem>();
                List<CheckinItem> assignChangesToDelta = new List<CheckinItem>();
                List<CheckinItem> buildCheckinsNotAssigned = new List<CheckinItem>();

                //Get Build Definition, Build Quality names
                String buildDefinition = Properties.Settings.Default.BuildDefinition;

                ////Find last two builds for this build definition with configured Build Quality  
                var build = BuildServer.GetBuildDefinition("Prefix", buildDefinition); //IPSCollection?
                var lastBuildSet = build.QueryBuilds().Where(b => b.BuildNumber == buildInfo.BuildNumber || b.BuildNumber == buildInfo.PreviousBuildNumber)
                                          .OrderByDescending(b => b.BuildNumber).ToList();

                if (lastBuildSet.Count != 2)
                {
                    Exception missingBuildInfoEx = new Exception(String.Format("One of the recent ABC builds {0} or {1} were not found in TFS. AutoAssign Aborted", buildInfo.BuildNumber, buildInfo.PreviousBuildNumber));
                    throw (missingBuildInfoEx);
                }
                
                // Get a list of checkins for this changeset range
                for (int i = GetChangeSetId(lastBuildSet[1]) + 1; i <= GetChangeSetId(lastBuildSet[0]); i++)
                {
                    Changeset nextChangeSet = VcServer.GetChangeset(i, true, false, true);

                    //If nextChangeSet is a merge set against this baseline, recurse to get to the constituent root changes  
                    if (IsBaselineMergeSet(nextChangeSet))
                    {
                        string sMerge = String.Empty;
                        List<CheckinItem> mergedChanges = GetMergedChanges(nextChangeSet, VcServer);
                        mergedChanges.ForEach(ci => buildCheckins.Add(ci));
                    }
                    else
                    {
                        nextChangeSet.Changes.ToList().ForEach(c =>
                        {
                            //if the change is for the branch for the build definition, or merged in from previous branch 
                            //add it to the list of checkin items
                            if (c.Item.ServerItem.IndexOf(Properties.Settings.Default.ReleaseTfsRoot) > -1)
                            {
                                CheckinItem checkinItem = new CheckinItem(
                                    nextChangeSet.ChangesetId,
                                    nextChangeSet.Owner.Replace("NWIE\\", ""),
                                    nextChangeSet.OwnerDisplayName.Substring(0, nextChangeSet.OwnerDisplayName.IndexOf(" ")),
                                    nextChangeSet.OwnerDisplayName.Substring(nextChangeSet.OwnerDisplayName.IndexOf(" ") + 1),
                                    GetSourceFile(c.Item.ServerItem),
                                    GetBaseline(c.Item.ServerItem),
                                    GetTfsPath(c.Item.ServerItem),
                                    c.ChangeType,
                                    c.Item.CheckinDate);
                                buildCheckins.Add(checkinItem);
                            }
                        });
                    }
                }

                //========================================================================
                //Filter check-in list to include only files of impact for this run type
                //========================================================================

                GetRunControlItemList();
                buildCheckins.ForEach(ci =>
                {
                    if (IsInControlFileList(ci))
                    {
                        assignChangesToDelta.Add(ci);
                    }
                    else
                    {
                        //Log the check-in against the build with no delta assignment
                        buildCheckinsNotAssigned.Add(ci);
                    }
                });

                //==================================================================================================
                //If there were deltas for the run assign a delta to each developer in the list, 
                //change status to "assigned" and send notification
                //==================================================================================================
                if (assignChangesToDelta.Count() > 0)
                {
                    if (runDeltas)
                    {
                        InsertDeltaRecords(assignChangesToDelta);
                    }
                    else
                    {
                        LogEvent(String.Format(">>> {0} Control File check-ins were detected for this build, but the run had no deltas so Delta Assignments were not made. <<<", assignChangesToDelta.Count()), 0);
                    }
                }
                else
                {
                    LogEvent(String.Format(">>> {0} check-ins were detected for this build, but none met the auto-assign criteria. <<<", buildCheckins.Count()), 0);
                }

                if (buildCheckinsNotAssigned.Count() > 0)
                {
                    if (!runDeltas)
                    {
                        //If no deltas, log control file check ins as Not Assigned
                        LogUnassignedCheckIns(assignChangesToDelta);
                    }

                    //Log Unassigned Check Ins
                    LogUnassignedCheckIns(buildCheckinsNotAssigned);
                }

                return;
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return;
            }
        }

        /// <summary>
        /// Inserts unassigned checkins to the Delta Check In table with buildid
        /// </summary>
        /// <param name=List<CheckinItem></param>
        /// <returns>Void</returns>
        private static void LogUnassignedCheckIns(List<CheckinItem> checkinsNotAssigned)
        {
            LogInfoEvent();
            String errMsg = String.Empty;
            checkinsNotAssigned.ForEach(ci =>
            {
                try
                {
                    Int16 recipientId = GetRecipientIdFromUserId(ci.Developer, ci.FName, ci.LName);
                    if (recipientId == 0)
                    {
                        Exception ex = new Exception(String.Format("GetRecipientIdFromUserId: Could resolve RecipientId for user: {0}", ci.Developer));
                        throw ex;
                    }

                    using (SqlConnection conn = new SqlConnection(abcDBConx))
                    {
                        using (SqlCommand sqlComm = new SqlCommand("Util.abc_InsertUnassignedCheckin", conn))
                        {
                            sqlComm.CommandType = CommandType.StoredProcedure;
                            sqlComm.Parameters.AddWithValue("@developerId", recipientId);
                            sqlComm.Parameters.AddWithValue("@baseline", ci.Baseline);
                            sqlComm.Parameters.AddWithValue("@changeSetId", ci.ChangeSetId);
                            sqlComm.Parameters.AddWithValue("@changeType", ci.ChangeType.ToString());
                            sqlComm.Parameters.AddWithValue("@checkinDate", ci.CheckinDate);
                            sqlComm.Parameters.AddWithValue("@sourceFile", ci.SourceFile);
                            sqlComm.Parameters.AddWithValue("@tfsPath", ci.TfsPath);
                            sqlComm.Parameters.AddWithValue("@buildId", buildInfo.BuildId);
                            conn.Open();
                            sqlComm.ExecuteNonQuery();
                        }
                    }
                }
                catch (Exception ex)
                {
                    LogEvent(String.Format("LogUnassignedCheckIns FAILED.  Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                }
            });

            return;
        }

        /// <summary>
        /// Insert records into the Delta Assignment table
        /// </summary>
        /// <param name=List<CheckinItem></param>
        /// <returns>Void</returns>
        private static void InsertDeltaRecords(List<CheckinItem> insertDeltaAssignments)
        {
            LogInfoEvent();
            String errMsg = String.Empty;
            insertDeltaAssignments.ForEach(da =>
            {
                try
                {
                    Int16 recipientId = GetRecipientIdFromUserId(da.Developer, da.FName, da.LName);
                    if (recipientId == 0)
                    {
                        Exception ex = new Exception(String.Format("GetRecipientIdFromUserId: Could resolve RecipientId for user: {0}", da.Developer));
                        throw ex;
                    }
                    using (SqlConnection conn = new SqlConnection(abcDBConx))
                    {
                        using (SqlCommand sqlComm = new SqlCommand("Util.abc_InsertDeltaAssignment", conn))
                        {
                            sqlComm.CommandType = CommandType.StoredProcedure;
                            sqlComm.Parameters.AddWithValue("@buildId", buildInfo.BuildId);
                            sqlComm.Parameters.AddWithValue("@runType", runType);
                            sqlComm.Parameters.AddWithValue("@autoAssigned", 1);
                            sqlComm.Parameters.AddWithValue("@assignedTo", recipientId);
                            sqlComm.Parameters.AddWithValue("@baseline", da.Baseline);
                            sqlComm.Parameters.AddWithValue("@changeSetId", da.ChangeSetId);
                            sqlComm.Parameters.AddWithValue("@changeType", da.ChangeType.ToString());
                            sqlComm.Parameters.AddWithValue("@checkinDate", da.CheckinDate);
                            sqlComm.Parameters.AddWithValue("@sourceFile", da.SourceFile);
                            sqlComm.Parameters.AddWithValue("@tfsPath", da.TfsPath);
                            sqlComm.Parameters.AddWithValue("@deltaStatusId", STATUS_ASSIGNED);
                            conn.Open();
                            sqlComm.ExecuteNonQuery();
                        }
                    }

                    //Send Assignment Notification
                    String mailErr = mailSender.SendAbcMessage("DeltaAssigned", buildInfo, recipientId);
                    if (mailErr.Length > 0)
                    {
                        LogEvent(String.Format("Error sending email {0}: {1}", "DeltaAssigned", mailErr), 2);
                    }
                    else
                    {
                        LogEvent(String.Format("{0} message sent to {1}.", "DeltaAssigned", da.Developer), 0);
                    }
                }
                catch (Exception ex)
                {
                    LogEvent(String.Format("AUTO-ASSIGNMENT FAILED.  Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                }
            });

            return;
        }

        /// <summary>
        /// Populates the runControlItemList global as needed
        /// </summary>
        /// <param name="changeSet"></param>
        /// <returns></returns>
        private static void GetRunControlItemList()
        {
            try
            {
                if (runControlItemList.Count == 0)
                {
                    DataSet ds = new DataSet("ControlItemList");
                    using (SqlConnection conn = new SqlConnection(abcDBConx))
                    {
                        using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetControlFilesByRunType", conn))
                        {
                            sqlComm.CommandType = CommandType.StoredProcedure;
                            sqlComm.Parameters.AddWithValue("@runType", runType);
                            SqlDataAdapter da = new SqlDataAdapter();
                            da.SelectCommand = sqlComm;
                            da.Fill(ds);

                            if (ds.Tables[0].Rows.Count > 1)
                            {
                                for (Int16 i = 0; i < ds.Tables[0].Rows.Count; i++)
                                {
                                    RunControlItem rci = new RunControlItem((String)ds.Tables[0].Rows[i]["SourceType"], (String)ds.Tables[0].Rows[i]["Value"]);
                                    runControlItemList.Add(rci);
                                }
                            }
                            else
                            {
                                LogEvent("No ControlFiles found for this Run Type.", FATAL);
                            }
                        }
                    }

                }
                return;
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return;
            }

        }

        /// <summary>
        /// Determines whether the passed CheckInItem is in the control file set for this RunType
        /// </summary>
        /// <param name="changeSet"></param>
        /// <returns></returns>
        private static Boolean IsInControlFileList(CheckinItem codeChange)
        {
            Boolean retVal = false;

            if (codeChange.SourceFile.IndexOf(".sql") > -1)
            {
                //See if codeChange matches any "S" records
                RunControlItem rciTest = new RunControlItem("S ", codeChange.SourceFile.Replace(".StoredProcedure.sql", ""));
                retVal = runControlItemList.Contains(rciTest);

                if (!retVal)
                {
                    //See if codeChange matches any "SF" records
                    runControlItemList.Where(rci => rci.SourceType == "SF").ToList().ForEach(tci =>
                    {
                        if (!retVal && codeChange.SourceFile.IndexOf(tci.Value) > -1)
                        {
                            retVal = true;
                        }
                    });
                }
            }
            else
            {
                String projectPath = codeChange.TfsPath.Replace(codeChange.Baseline.Replace("/", "\\"), "");
                projectPath = projectPath.Substring(0, projectPath.Length - 1);
                RunControlItem rciTest = new RunControlItem("D ", projectPath);
                retVal = runControlItemList.Contains(rciTest);
            }
            return retVal;
        }
        /// returns an RecipientID given a UserId
        /// optional: include first and last name to add to NotifyRecipients if not already existing
        private static Int16 GetRecipientIdFromUserId(String userId, String firstName = "", String lastName = "")
        {
            DataSet ds = new DataSet("RecipientId");
            try
            {
                using (SqlConnection conn = new SqlConnection(abcDBConx))
                {
                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetRecipientIdFromUserId", conn))
                    {
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;

                        //Pass first and last name so that a new record will be created if necessary
                        sqlComm.Parameters.AddWithValue("@userId", userId);
                        sqlComm.Parameters.AddWithValue("@firstName", firstName);
                        sqlComm.Parameters.AddWithValue("@lastName", lastName);
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count != 1)
                        {
                            String errMsg = String.Format("Invalid results returned for userId {0}", userId);
                            LogEvent(errMsg, 2);
                            return 0;
                        }
                        return Int16.Parse(ds.Tables[0].Rows[0]["RecipientId"].ToString());
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent(String.Format("Method {0} threw exception {1}", System.Reflection.MethodBase.GetCurrentMethod().Name, ex.Message), 2);
                return 0;
            }

        }

        /// <summary>
        /// Determines whether the passed changeset is a mergeset and whether it is a merge against the current baseline (TfsRoot)
        /// </summary>
        /// <param name="changeSet"></param>
        /// <returns></returns>
        private static Boolean IsBaselineMergeSet(Changeset changeSet)
        {
            Boolean retVal;
            var mergeIndicators = Properties.Settings.Default.MergeIndicators.Cast<string>().ToList();
            retVal = mergeIndicators.Exists(v => changeSet.Comment.ToLower().Contains(v.ToLower()))
                && changeSet.Comment.Contains(String.Format("==> R{0}", GetReleaseDate(Properties.Settings.Default.ReleaseTfsRoot)));
            return retVal;
        }


        //Retrieve the ReleaseDate from the TFS root string
        private static string GetReleaseDate(String tfsRoot)
        {
            return tfsRoot.Substring(tfsRoot.IndexOf("R20") + 1);
        }

        //Retrieve the Change Set Id from the build object
        private static int GetChangeSetId(IBuildDetail deployedBuild)
        {
            return int.Parse(deployedBuild.SourceGetVersion.Substring(1));
        }

    }
}