using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;
using System.ComponentModel.DataAnnotations;

namespace Vinmove.Models
{
    public class Employee
    {

        

        public int ContactID { get; set; }


         [Display(Name = "User name")]
         [Required(ErrorMessage = "Email is required (we promise not to spam you!).")]
        public string FullName { get; set; }
      
        
        public string Division { get; set; }
      [Required(ErrorMessage = "Fullname is required")]
        
        public int Extension { get; set; }
        public string Phone { get; set; }

        public string Designation { get; set; }
        public int DivisonSortOrder { get; set; }
        public int SortOrder { get; set; }
        public string Recordstatus { get; set; }


        public List<Employee> GetEmployees()
        {

            List<Employee> result = new List<Employee>();

            //Create the SQL Query for returning all the articles
            string sqlQuery = String.Format("SELECT * from DaiContacts Where Recordstatus ='Active' Order By DivisonSortOrder ,SortOrder");

            //Create and open a connection to SQL Server 
            SqlConnection connection = new SqlConnection(DatabaseHelper.ConnectionString);
            connection.Open();

            SqlCommand command = new SqlCommand(sqlQuery, connection);

            //Create DataReader for storing the returning table into server memory
            SqlDataReader dataReader = command.ExecuteReader();

           Employee employee = null;

            //load into the result object the returned row from the database
            if (dataReader.HasRows)
            {
                while (dataReader.Read())
                {
                    employee = new Employee();

                 
           
                    employee.FullName = dataReader["FullName"].ToString();
                    employee.Division = dataReader["Division"].ToString();

                 
                    employee.Extension = Convert.ToInt32(dataReader["Extension"]);
                    employee.Phone = dataReader["Phone"].ToString();
                    
                    employee.Designation = dataReader["Designation"].ToString();
                    
                     
                    
            			


                    result.Add(employee);
                }
            }

            return result;

        }

        public Employee GetEmployeebyId(int userId)
        {
            Employee result = new Employee();

            //Create the SQL Query for returning an article category based on its primary key
            string sqlQuery = String.Format("select * from users where UserID={0}", userId);

            //Create and open a connection to SQL Server 
            SqlConnection connection = new SqlConnection(DatabaseHelper.ConnectionString);
            connection.Open();

            SqlCommand command = new SqlCommand(sqlQuery, connection);

            SqlDataReader dataReader = command.ExecuteReader();

            //load into the result object the returned row from the database
            if (dataReader.HasRows)
            {
                while (dataReader.Read())
                {
                       result.FullName = dataReader["UserCode"].ToString();
                   
                }
            }

            return result;
        }


        public int SaveEmployee(Employee employee)
        {

  
            
            //Create the SQL Query for inserting an article
            string createQuery = String.Format("Insert into DaiContacts (FullName, Designation ,Division,Extension,Phone,DivisonSortOrder,SortOrder,Recordstatus) Values('{0}', '{1}', '{2}', '{3}', {4}, '{5}', {6},'{7}' );"
                + "Select @@Identity", employee.FullName, employee.Designation, employee.Division, employee.Extension, employee.Phone, employee.DivisonSortOrder, employee.SortOrder, employee.Recordstatus);

            //Create the SQL Query for updating an article
          string updateQuery = String.Format("Update DaiContacts SET FullName='{0}', Designation = '{1}', Division ='{2}', Extension = '{3}', Phone = {4},DivisonSortOrder ='{5}', SortOrder = {6}, Recordstatus = '{7}' Where ContactID = {8};",
            employee.FullName,employee.Designation,employee.Division,employee.Extension, employee.Phone,employee.DivisonSortOrder,employee.SortOrder,employee.Recordstatus,employee.ContactID);

            //Create and open a connection to SQL Server 
            SqlConnection connection = new SqlConnection(DatabaseHelper.ConnectionString);
            connection.Open();

            //Create a Command object
            SqlCommand command = null;

          if (employee.ContactID != 0)
            command = new SqlCommand(updateQuery, connection);
          else
                command = new SqlCommand(createQuery, connection);

            int savedContactID = 0;
            try
            {
                //Execute the command to SQL Server and return the newly created ID
                var commandResult = command.ExecuteScalar();
                if (commandResult != null)
                {
                    savedContactID = Convert.ToInt32(commandResult);
                }
                else
                {
                    //the update SQL query will not return the primary key but if doesn't throw exception 
                    //then we will take it from the already provided data
                    savedContactID = employee.ContactID;
                }
            }
            catch (Exception ex)
            {
                //there was a problem executing the script
            }

            //Close and dispose
            command.Dispose();
            connection.Close();
            connection.Dispose();

            return savedContactID;
        }




    }
}

