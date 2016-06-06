using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;

namespace Vinmove.Models
{
   
   
    
    public class Calendar
    {
       public string DayPart { get; set; }
       public int DayNumber { get; set; }

       public string HolidayName { get; set; }


       public string DriverName { get; set; }
       public string VacationDesignation { get; set; }

       public int DriverID { get; set; }
       public string BenefitPaytype { get; set; }
       public string DriverNumber { get; set; }


        public string i1CalendarDate { get; set; }
        public int i1 {get; set; }
        public string i1HolidayName { get; set; }


        public string i2CalendarDate { get; set; }
        public int i2 {get; set; }
        public string i2HolidayName { get; set; }

        public string i3CalendarDate { get; set; }
        public int i3 {get; set; }
        public string i3HolidayName { get; set; }

        public string i4CalendarDate { get; set; }
        public int i4 {get; set; }
        public string i4HolidayName { get; set; }

        public string i5CalendarDate { get; set; }
        public int i5 {get; set; }
        public string i5HolidayName { get; set; }

        public string i6CalendarDate { get; set; }
        public int i6 {get; set; }
        public string i6HolidayName { get; set; }

        public string i7CalendarDate { get; set; }
        public int i7 {get; set; }
        public string i7HolidayName { get; set; }

        

        public List<Calendar> GetCalendarData(int monthID)
         //   int yearID
        {

           
           List<Calendar> result = new List<Calendar>();

            //Create the SQL Query for returning an article category based on its primary key
           string sqlQuery = String.Format(@"SELECT CONVERT(Varchar(10),CalendarDate,101) as CalendarDate,CONVERT(Varchar(10),DATEPART(MONTH,CalendarDate)) + '/' +Convert(Varchar(10),DATEPART(DAY,CalendarDate)) as Calendarpartdate,
                                        DayNumber,HolidayName
                                        FROM Calendar C
                                        LEFT JOIN Holiday H ON  C.Calendardate = H.Holidaydate
                                WHERE  Year(calendardate)=2016 and Month(calendardate)= {0} Order 
            By Calendardate", monthID);
           //monthID
           //and month(calendardate)={1}
            //year(Calendardate)=2016 order by calendarid desc");

            
            //Create and open a connection to SQL Server 
            SqlConnection connection = new SqlConnection(DatabaseHelper.ConnectionString);
            connection.Open();

            SqlCommand command = new SqlCommand(sqlQuery, connection);

            SqlDataReader dataReader = command.ExecuteReader();

            Calendar calendar = null;
            var i = 0;
            calendar = new Calendar();
            //load into the result object the returned row from the database
            if (dataReader.HasRows)
              
            {
                while (dataReader.Read())
                {

                  
                  
                   

                 // for (var i = 1; i < 6; i++)

                
                     if (Convert.ToInt32(dataReader["DayNumber"]) == 1)
                    {
                        calendar.i1 = Convert.ToInt32(dataReader["DayNumber"]);
                        calendar.i1CalendarDate = dataReader["CalendarDate"].ToString();
                        calendar.i1HolidayName = dataReader["HolidayName"].ToString();

                        //result.Add(calendar);
                      
                    }

                     else if (Convert.ToInt32(dataReader["DayNumber"]) == 2)
                     {
                         calendar.i2 = Convert.ToInt32(dataReader["DayNumber"]);
                         calendar.i2CalendarDate = dataReader["CalendarDate"].ToString();
                         calendar.i2HolidayName = dataReader["HolidayName"].ToString();
                      //   result.Insert(1,calendar);
                     }

                     else if (Convert.ToInt32(dataReader["DayNumber"]) == 3)
                     {
                         calendar.i3 = Convert.ToInt32(dataReader["DayNumber"]);
                         calendar.i3CalendarDate = dataReader["CalendarDate"].ToString();
                         calendar.i3HolidayName = dataReader["HolidayName"].ToString();
                    
                     }

                     else if (Convert.ToInt32(dataReader["DayNumber"]) == 4)
                     {
                         calendar.i4 = Convert.ToInt32(dataReader["DayNumber"]);
                         calendar.i4CalendarDate = dataReader["CalendarDate"].ToString();
                         calendar.i4HolidayName = dataReader["HolidayName"].ToString();
                         
                     }

                     else if (Convert.ToInt32(dataReader["DayNumber"]) == 5)
                     {
                         calendar.i5 = Convert.ToInt32(dataReader["DayNumber"]);
                         calendar.i5CalendarDate = dataReader["CalendarDate"].ToString();
                         calendar.i5HolidayName = dataReader["HolidayName"].ToString();
                         
                     }

                     else if (Convert.ToInt32(dataReader["DayNumber"]) == 6)
                     {
                         calendar.i6 = Convert.ToInt32(dataReader["DayNumber"]);
                         calendar.i6CalendarDate = dataReader["CalendarDate"].ToString();
                         calendar.i6HolidayName = dataReader["HolidayName"].ToString();
                       
                     }

                     else if (Convert.ToInt32(dataReader["DayNumber"]) == 7)
                     {
                         calendar.i7 = Convert.ToInt32(dataReader["DayNumber"]);
                         calendar.i7CalendarDate = dataReader["CalendarDate"].ToString();
                         calendar.i7HolidayName = dataReader["HolidayName"].ToString();
                        // result.Add(calendar);
                         result.Insert(i, calendar);
                         i = i + 1;
                         calendar = new Calendar();
                     }


                    
                        
                     

                }
            }

            result.Insert(i, calendar);
            return result;
        }




        public List<Calendar> GetDriverData(String pcalendardate)
        //   int yearID
        {

            // List<Employee> result = new List<Employee>();
            List<Calendar> result = new List<Calendar>();

            //Create the SQL Query for returning an article category based on its primary key
            string sqlQuery = String.Format(@"SELECT D.DriverNumber,UPPER(LEFT(DN.BenefitPayType,3))as BenefitPayType,U.FirstName + ' ' + U.LastName as DriverName,C1.Value1 as VacDesgn,CONVERT(varchar(10),C.CalendarDate,101) as RequestDate FROM  Calendar C
            LEFT JOIN DriverNotAvailableDates DN  ON (C.Calendardate >= DN.NotAvailableFromDate  AND C.Calendardate < DATEADD(day,1,DN.NotAvailableToDate) )
            LEFT JOIN Driver D ON DN.DriverID = D.DriverID
            LEFT JOIN Users U ON D.UserID = U.UserID
            LEFT JOIN CODE C1 ON D.VacationDesignation = C1.Code AND C1.CodeType= 'VacationDesignation'
            WHERE RequestStatus ='Approved'AND ISNULL(NonPayrollInd,'') <>1 AND 
            Convert(varchar(10),C.Calendardate,101) = {0} Order By C1.Value1,U.FirstName", pcalendardate);

 



            //Create and open a connection to SQL Server 
            SqlConnection connection = new SqlConnection(DatabaseHelper.ConnectionString);
            connection.Open();

            SqlCommand command = new SqlCommand(sqlQuery, connection);

            SqlDataReader dataReader = command.ExecuteReader();

            Calendar calendar = null;

            //load into the result object the returned row from the database
            if (dataReader.HasRows)
            {
                while (dataReader.Read())
                {

                    calendar = new Calendar();
                    //calendar.DriverID = Convert.ToInt32(dataReader["DriverID"]);
                    calendar.DriverName  = dataReader["DriverName"].ToString();
                    calendar.VacationDesignation = dataReader["VacDesgn"].ToString();
                    calendar.DriverNumber = dataReader["DriverNumber"].ToString();
                    calendar.BenefitPaytype= dataReader["BenefitPaytype"].ToString();



                    
                    result.Add(calendar);
                }
            }

            return result;
        }




    
    }
}