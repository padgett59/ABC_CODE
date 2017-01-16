
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Data.SqlClient;
using System.Data;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Net.Mail;
using Prefix;

namespace Abc_Notify
{

    public class Notify
    {
        //Contructor
        public Notify(String MailServer, String Region = "", String AbcWebUrl = "[Not Set]")
        {
            mailServer = MailServer;
            region = Region;
            abcWebUrl = AbcWebUrl;
        }

        /// <summary>
        /// Gets or sets the mail server.
        /// </summary>
        /// <value>The mail server.</value>
        private String mailServer;

        /// <summary>
        /// Gets or sets the test region.
        /// </summary>
        /// <value>The test region.</value>
        private String region;

        /// <summary>
        /// Gets or sets the DB connection string.
        /// </summary>
        /// <value>The mail server.</value>
        public String conxString;

        /// <summary>
        /// Gets or sets the TFS connection string.
        /// </summary>
        /// <value>The mail server.</value>
        private String tfsConxString;

        /// <summary>
        /// Gets or sets the web URL for the region.
        /// </summary>
        /// <value>The mail server.</value>
        public String abcWebUrl;

        /// <summary>
        /// Gets or sets the Abc run type
        /// </summary>
        /// <value>The mail server.</value>
        public DeclareWarehouse.EnumAbcRunType abcRunType;

        /// <summary>
        /// Gets or sets the log message indicator.
        /// </summary>
        /// <value>Log Message.</value>
        private bool LogMessage;

         /// <summary>
        /// Gets or sets the message id.
        /// </summary>
        /// <value>Log Message.</value>
        private Int16 MessageId;

        ///// <summary>
        ///// Build Information 
        ///// </summary>
        ///// <value>The mail server.</value>
        public class BuildInfo
        {
            public Int32 BuildId { get; set; }
            public String BuildNumber { get; set; }
            public DateTime StartTime { get; set; }
            public Int32 ErrorCount { get; set; }
            public Boolean Delta { get; set; }
            public Int32 DeltaCount { get; set; }
            public string DeltaStatus { get; set; }
            public TimeSpan ElapsedTime { get; set; }
            public String PreviousBuildNumber { get; set; }
        }


        /// <summary>
        /// Sends the specified message.
        /// </summary>
        /// <param name="message">The message.</param>
        //// static void SendAbcMessage(String messageAlias)
        /// returns error if any, or empty string
        public String SendAbcMessage(String messageAlias, BuildInfo buildInfo = null, Int16 recipientId = 0,string bodyHtml=null)
        {
            try
            {
                //Get the Message Info
                DataSet ds = new DataSet("MsgInfo");
                using (SqlConnection conn = new SqlConnection(this.conxString))
                {

                    using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetMessageInfo", conn))
                    {
                        sqlComm.Parameters.AddWithValue("@Alias", messageAlias);
                        sqlComm.CommandType = CommandType.StoredProcedure;
                        SqlDataAdapter da = new SqlDataAdapter();
                        da.SelectCommand = sqlComm;
                        da.Fill(ds);

                        if (ds.Tables[0].Rows.Count != 1)
                        {
                            String errMsg = String.Format("Invalid results returned for alias {0}",
                                messageAlias);
                            return errMsg;
                        }

                        if (ds.Tables[0].Rows[0]["GroupId"] == null && recipientId == null)
                        {
                            String errMsg = String.Format("No recipients available for message {0}", messageAlias);
                            return errMsg;
                        }

                        MailMessage message = new MailMessage();

                        if (recipientId == 0)
                        {
                            foreach (DataRow recipRow in ds.Tables[1].Rows)
                            {
                                message.To.Add(recipRow["EmailAddress"].ToString());
                            }
                        }
                        else
                        {
                            String eMailAddress = this.GetEmailFromId(recipientId);

                            //if not an email address it an error occurred
                            if (eMailAddress.IndexOf("@") == -1)
                            {
                                Exception ex = new Exception(eMailAddress);
                                throw ex;
                            }
                            message.To.Add(eMailAddress);
                        }

                        String runDescription = String.Empty;
                        switch(abcRunType)
                        {
                            case DeclareWarehouse.EnumAbcRunType.AbcCore:
                                runDescription = "BuildBcp";
                                break;
                            case DeclareWarehouse.EnumAbcRunType.Projection:
                                runDescription = "Projections";
                                break;
                        }

                        message.Subject = String.Format("[{0} - {1}] {2}", this.region, runDescription, ds.Tables[0].Rows[0]["Subject"].ToString());
                        if (bodyHtml != null)
                        {
                            message.Body = ds.Tables[0].Rows[0]["Message"].ToString() + " <br/> <br/> <br/> " + bodyHtml;
                        }
                        else
                        {
                        message.Body = ds.Tables[0].Rows[0]["Message"].ToString();

                        }
                        LogMessage = Convert.ToBoolean(ds.Tables[0].Rows[0]["LogMessage"]);
                        MessageId= Convert.ToInt16(ds.Tables[0].Rows[0]["MessageId"]);

                        SendEmail(message, buildInfo,recipientId);
                        return String.Empty;
                    }
                }
            }
            catch (Exception ex)
            {
                return ex.Message;
            }

        }

        /// <summary>
        /// Sends the specified message.
        /// </summary>
        /// <param name="message">The message.</param>
        /// <param name="region">The region.</param>
        //// internal void SendEmail(EmailMessage message)
        /// returns error if any, or empty string
        private String SendEmail(MailMessage message, BuildInfo buildInfo = null,Int16 recipientId = 0)
        {
            string strLogError=string.Empty;
            MailAddress abcFromAddress = new MailAddress("noReplyABC@AutoBuildCompare.com", "Automated Build Compare");
            message.From = abcFromAddress;
            message.Body = ResolveMessageBody(message.Body, buildInfo);
            message.Body += "<br><br><span style=\"font-size: 12px\"><i>[This is a system generated message from an unmonitored address.]</i></span>";
            message.IsBodyHtml = true;
            SmtpClient client = new SmtpClient(this.mailServer);
            client.Credentials = System.Net.CredentialCache.DefaultNetworkCredentials;
            try
            {
                client.Send(message);
                
                if (LogMessage == true)
                {
                  strLogError= LogNotifyfMessage(buildInfo, message.Body, message.Subject, recipientId);
                }

                return strLogError; // Returns exception details of LogNotifyfMessage() if there is any exception in it.Otherwise it just returns Nothing to caller. 
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        /// returns an email address given a recipientId
        private string GetEmailFromId(Int16 recipientId)
        {
            DataSet ds = new DataSet("eMailAddress");
            using (SqlConnection conn = new SqlConnection(this.conxString))
            {
                using (SqlCommand sqlComm = new SqlCommand("Util.abc_GetEmailFromId", conn))
                {
                    sqlComm.CommandType = CommandType.StoredProcedure;
                    SqlDataAdapter da = new SqlDataAdapter();
                    da.SelectCommand = sqlComm;
                    sqlComm.Parameters.AddWithValue("@recipientId", recipientId);
                    da.Fill(ds);

                    if (ds.Tables[0].Rows.Count != 1)
                    {
                        String errMsg =
                            String.Format(
                                "Invalid results returned from GetEmailFromId. Rows returned {0} for recipientId {1}",
                                ds.Tables[0].Rows.Count, recipientId);
                        //Exception ex = new Exception(errMsg);
                        //throw ex;
                        return errMsg;
                    }
                    return ds.Tables[0].Rows[0]["eMailAddress"].ToString();
                }
            }
        }

        private String ResolveMessageBody(String msgBody, BuildInfo buildInfo = null)
        {
            // ~t~: current time
            // ~b~: build number
            // ~d~: delta number
            // ~ec~: run error count
            // ~dc~: delta count [0 or 1]
            // ~s~: delta status
            // ~et~: run elapsed time
            // ~r~: region
            // ~url~: abcWebUrl

            String retVal = msgBody;
            String buildNumber = String.Empty;
            if (buildInfo != null)
            {
                if (buildInfo.BuildNumber != null)
                {
                        buildNumber = buildInfo.BuildNumber;
                }
            }
            retVal = retVal.Replace("~t~", DateTime.Now.ToString("G"));
            retVal = retVal.Replace("~b~", buildNumber);
            retVal = retVal.Replace("~r~", this.region);
            retVal = retVal.Replace("~url~", String.Format("<a href=\"{0}\">{0}</a>", this.abcWebUrl));

            Regex regexExp = new Regex("~ec~|~dc~|~ds~|~et~");
            if (regexExp.IsMatch(msgBody))
            {
                if (buildInfo == null)
                {
                    Exception ex = new Exception("ERROR: This message requires build information.");
                    throw ex;
                }
                retVal = retVal.Replace("~ec~", buildInfo.ErrorCount.ToString());
                retVal = retVal.Replace("~dc~", buildInfo.DeltaCount.ToString());
                retVal = retVal.Replace("~et~", buildInfo.ElapsedTime.ToString());

                //Delta Status
                if (buildInfo.DeltaStatus != null)
                {
                    retVal = retVal.Replace("~ds~", buildInfo.DeltaStatus.ToUpper());
                }
            }
            return retVal;
        }

        private string LogNotifyfMessage(BuildInfo buildInfo, string message,string subject, int recipientId)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(this.conxString))
                {
                    using (SqlCommand cmd = new SqlCommand("util.abc_InsertNotifyMessageLog", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        conn.Open();
                        cmd.Parameters.AddWithValue("@MessageId", MessageId.ToString());
                        cmd.Parameters.AddWithValue("@RecipientId", recipientId);
                        cmd.Parameters.AddWithValue("@Region", this.region);
                        cmd.Parameters.AddWithValue("@Subject", subject);
                        cmd.Parameters.AddWithValue("@MessageSent", message);
                        cmd.Parameters.AddWithValue("@MessageSentOn", DateTime.Now);
                        cmd.ExecuteNonQuery();
                        conn.Close();
   
                       
                    }
                }

                return string.Empty;
            }
            catch (Exception ex)
            {

                return ex.Message; 
            }
        }
    }
}
