using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Linq.Mapping;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Data.Entity;

using Microsoft.Ajax.Utilities;

namespace ABC.Web.Models
{

    public class AbcDBContext : DbContext
    {
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            //Set default Db Schema 
            modelBuilder.HasDefaultSchema("Util");

            //Map entities to tables
            modelBuilder.Entity<BuildInfo>().ToTable("BuildInfo");
            modelBuilder.Entity<BuildSummary>().ToTable("BuildSummary");
            modelBuilder.Entity<BuildSummary>().HasKey(a => new { a.BuildId, a.TableName, a.Product });
            modelBuilder.Entity<RunLog>().ToTable("RunLog");
            modelBuilder.Entity<AmtCode>().ToTable("AmountCodes", "dbo");
            modelBuilder.Entity<AttributeCode>().ToTable("AttributeCodes", "dbo");
            modelBuilder.Entity<DeltaCheckIn>().ToTable("DeltaCheckIn");
            modelBuilder.Entity<DeltaAssignment>().ToTable("DeltaAssignment");
            modelBuilder.Entity<TransactionCodes>().ToTable("TransactionCodes", "dbo");
            modelBuilder.Entity<NotifyGroupMembers>().HasKey(Ng => new { Ng.GroupId, Ng.RecipientId });            
        }

        //DbSet instanaces must match pluralized table names unless mapped above
        public DbSet<NotifyRecipient> NotifyRecipients { get; set; }
        public DbSet<DeltaStatus> DeltaStatus { get; set; }
        public DbSet<BuildInfo> BuildInfo { get; set; }
        public DbSet<BuildSummary> BuildSummary { get; set; }
        public DbSet<DeltaAssignment> DeltaAssignments { get; set; }
        public DbSet<NotifyGroupMembers> NotifyGroupMembers { get; set; }
        public DbSet<NotifyGroups> NotifyGroups { get; set; }
        public DbSet<RunLog> RunLog { get; set; }
        public DbSet<AmtCode> AmountCodes { get; set; }
        public DbSet<DeltaCheckIn> DeltaCheckIns { get; set; }
        public DbSet<TransactionCodes> TransactionCodes { get; set; }
        public DbSet<AttributeCode> AttributeCodes { get; set; }
    }

    public class AmtCode
    {
        [Key]
        public Int16 AmountCode { get; set; }
        public String Constant { get; set; }
        public String AmountName { get; set; }
        public Byte Corrective { get; set; }
        public String Category { get; set; }
        public String Description { get; set; }
        public String Format { get; set; }
        public String Structure { get; set; }
    }

    public class AttributeCode
    {
        [Key]
        public Int16 Code { get; set; }
        public String Name { get; set; }
    }

    public class NotifyRecipient
    {
        [Key]
        public Int16 RecipientId { get; set; }
        public String EmailAddress { get; set; }
        public String FName { get; set; }
        public String LName { get; set; }
        public int? RoleId { get; set; }
    }

    public class DeltaStatus
    {
        [Key]
        public Int16 DeltaStatusId { get; set; }
        public String Status { get; set; }
    }


    public class BuildInfo
    {
        [Key]
        public Int32 BuildId { get; set; }
        public String BuildNumber { get; set; }
        public DateTime BuildDateTime { get; set; }
        public Int32? ErrorCount { get; set; }
        public Boolean? Deltas { get; set; }
        public Int32? DeltaCount { get; set; }
        public String RunType { get; set; }
        public Boolean DeltasDeleted { get; set; }
    }

    public class BuildSummary
    {
        public Int32 BuildId { get; set; }
        public String TableName { get; set; }
        public Byte Product { get; set; }
        public Int32? TotalRecords { get; set; }
        public Int32? DiffRecords { get; set; }
        public String RunType { get; set; }
    }



    public enum enumTableStatus : byte
    {
        NoRecords,
        NoVariants,
        Variants
    }

    public class NotifyGroupMembers
    {
        public byte GroupId { get; set; }
        public Int16 RecipientId { get; set; }
    }

    public class NotifyGroups
    {
        [Key]
        public byte GroupId { get; set; }
        public string GroupName { get; set; }
    }

    public class RunLog
    {
        [Key]
        public Int32 LogEntryId { get; set; }
        public DateTime LogEntryDateTime { get; set; }
        public string Application { get; set; }
        public string Logger { get; set; }
        public string LogMessage { get; set; }
        public Byte Severity { get; set; }
        public string SecondsElapsed { get; set; }
        public string BuildNumber { get; set; }
        public string RunType { get; set; }
    }

    public class TransactionCodes
    {
        [Key]
        public Int16 Transaction { get; set; }
        public string Name { get; set; }
        public string Code { get; set; }
       
    }

}

