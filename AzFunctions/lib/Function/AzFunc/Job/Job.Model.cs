using System.Collections.Generic;
using System.Collections;
using Microsoft.Azure.Cosmos.Table;
using System.Management.Automation;
using System;
// using System.Text.Json;
// using System.Text.Json.Serialization;
namespace FakeProfile
{
    public class Job
    {
        // public System.Collections.Generic.List<Job> test
        public JobName Name {get;set;}
        public System.Guid RowKey {get;set;}
        public string Children {get;set;}
        public string Comment {get;set;}
        public bool Completed {get;set;}
        public Guid Parent {get;set;}
        // public Job Parent {get;set;}
        public string value {get;set;}
        public string Source {get;set;}

        public Tags Tag {get;set;}

        public Job()
        {
            Name = JobName.None;
        }

        public bool HasChildren()
        {
            return !string.IsNullOrEmpty(this.Children);
        }

        public bool HasParent()
        {
            return this.Parent != Guid.Empty;
        }
    }

    public enum JobName
    {
        None,
        Instance,
        Generate,
        Scale,
        Detect
    }

    public enum Tags
    {
        None,
        Waiting,
        Processing,
        Completed,
    }
}