using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.SqlClient;
using System.Data;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Net.Mail;
using System.Windows.Forms;

namespace AutomatedBuild
{

    public static class Notify
    {
        static Notify()
        {
            MailServer = Properties.Settings.Default.EmailServer;
        }

        /// <summary>
        /// Gets or sets the mail server.
        /// </summary>
        /// <value>The mail server.</value>
        public static string MailServer { get; set; }

        /// <summary>
        /// Sends the specified message.
        /// </summary>
        /// <param name="message">The message.</param>
        /// <param name="region">The region.</param>
        //// internal void SendEmail(EmailMessage message)
        public static void SendEmail(MailMessage message)
        {
            MailAddress abcFromAddress = new MailAddress("noReplyABC@AutoBuildCompare.com", "No Reply at Automated Build Compare");
            message.From = abcFromAddress;
            message.Body = ResolveMessageBody(message.Body);
            message.Body += "\n\n[This is a system generated message from an unmonitored address.]";
            SmtpClient client = new SmtpClient(MailServer);
            client.Credentials = System.Net.CredentialCache.DefaultNetworkCredentials;
            //EnforceEmailPolicies(message, region);
            try
            {
                client.Send(message);
            }
            catch (Exception ex)
            {
                RunABC.LogEvent(ex.Message, 1);
            }
        }

        /// <summary>
        /// Sends the specified message.
        /// </summary>
        /// <param name="message">The message.</param>
        //// static void SendAbcMessage(String messageAlias)
        public static void SendAbcMessage(String messageAlias, Int16 recipientId = 0)
        {
            try
            {
                //Get the Message Info
                DataSet ds = new DataSet("MsgInfo");
                using (SqlConnection conn = new SqlConnection(RunABC.pv.WarehouseConnection))
                {
                    SqlCommand sqlComm = new SqlCommand("Util.abc_GetMessageInfo", conn);
                    sqlComm.Parameters.AddWithValue("@Alias", messageAlias);
                    sqlComm.CommandType = CommandType.StoredProcedure;
                    SqlDataAdapter da = new SqlDataAdapter();
                    da.SelectCommand = sqlComm;
                    da.Fill(ds);

                    if (ds.Tables[0].Rows.Count != 1)
                    {
                        String errMsg = String.Format("Invalid results returned for alias {0}",
                            messageAlias, 1);
                        RunABC.LogEvent(errMsg);
                    }

                    if (ds.Tables[0].Rows[0]["GroupId"] == null && recipientId == null)
                    {
                        String errMsg = String.Format("No recipients available for message {0}", messageAlias, 1);
                        RunABC.LogEvent(errMsg);
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
                        message.To.Add(RunABC.GetEmailFromId(recipientId));
                    }
                    message.Subject = ds.Tables[0].Rows[0]["Subject"].ToString();
                    message.Body = ds.Tables[0].Rows[0]["Message"].ToString();
                    SendEmail(message );
                }
            }
            catch (Exception ex)
            {
                RunABC.LogEvent(ex.Message);
            }

        }

        private static String ResolveMessageBody(String msgBody)
        {
            // ~t~: current time
            // ~b~: build number
            // ~d~: delta number
            // ~ec~: run error count
            // ~dc~: delta count [0 or 1]
            // ~s~: delta status
            // ~et~: run elapsed time

            String retVal = msgBody;
            retVal = retVal.Replace("~t~", DateTime.Now.ToString("G"));
            retVal = retVal.Replace("~b~", RunABC.buildInfo.BuildNumber.ToString());

            //Update the BuildInfo as needed
            Regex regexExp = new Regex("~ec~|~dc~|~ds~|~et~");
            if (regexExp.IsMatch(msgBody))
            {
                if (RunABC.buildInfo.ErrorCount == null)
                {
                    RunABC.UpdateBuildInfo();
                }
                retVal = retVal.Replace("~ec~", RunABC.buildInfo.ErrorCount.ToString());
                retVal = retVal.Replace("~dc~", RunABC.buildInfo.DeltaCount.ToString());
                retVal = retVal.Replace("~et~", RunABC.buildInfo.ElapsedTime.ToString());
                //DEBUG - Set up deltas
                if (RunABC.buildInfo.DeltaStatus != null)
                {
                    retVal = retVal.Replace("~ds~", RunABC.buildInfo.DeltaStatus.ToUpper());
                }
            }
            return retVal;
        }
    }
}
