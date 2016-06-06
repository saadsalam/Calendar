using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Vinmove.Models;

namespace Vinmove.Controllers
{
    public class CalendarController : Controller
    {
        //
        // GET: /Calendar/

        public ActionResult Index(String id)
        {
            //id here is calendar date

                Calendar C2 = new Calendar();
                //{
                // EmployeeId = 101,
                // Name = "John",
                //Gender = "Male",
                // City = "London"
                // GetEmployeebyId(1);
                //};

                return PartialView(C2.GetDriverData(id));
            
            //return View();
        }



        public ActionResult test()
        {

            string s="Hello Gi";
            return PartialView();

            //return View();
        }


        public ActionResult Details(int id)
        {

            //id here is 

            Calendar C1 = new Calendar();
            //{
            // EmployeeId = 101,
            // Name = "John",
            //Gender = "Male",
            // City = "London"
            // GetEmployeebyId(1);
            //};

            // @{var theMonth = DateTime.Now.Month;}
               
           
              if (id== 1)
                    {
                        ViewBag.Monthname = "January";
                    }

                     else if (id== 2)
                    {
                        ViewBag.Monthname = "February";
                    }

              else if (id == 3)
              {
                  ViewBag.Monthname = "March";
              }
              else if (id == 4)
              {
                  ViewBag.Monthname = "April";
              }
              else if (id == 5)
              {
                  ViewBag.Monthname = "May";
              }
              else if (id == 6)
              {
                  ViewBag.Monthname = "June";
              }
              else if (id == 7)
              {
                  ViewBag.Monthname = "July";
              }
              else if (id == 8)
              {
                  ViewBag.Monthname = "August";
              }
              else if (id == 9)
              {
                  ViewBag.Monthname = "September";
              }
              else if (id == 10)
              {
                  ViewBag.Monthname = "October";
              }
              else if (id == 11)
              {
                  ViewBag.Monthname = "November";
              }
              else if (id == 12)
              {
                  ViewBag.Monthname = "December";
              }

           

              List<SelectListItem> items = new List<SelectListItem>();

              items.Add(new SelectListItem { Text = "January",Value = "1" });
              items.Add(new SelectListItem { Text = "February",Value = "2" });
              items.Add(new SelectListItem { Text = "March",Value = "3"});
              items.Add(new SelectListItem { Text = "April",Value = "4" });

              items.Add(new SelectListItem { Text = "May",Value = "5" });
              items.Add(new SelectListItem { Text = "June",Value = "6" });
              items.Add(new SelectListItem { Text = "July",Value = "7" });
              items.Add(new SelectListItem { Text = "August",Value = "8" });

              items.Add(new SelectListItem { Text = "September",Value = "9" });
              items.Add(new SelectListItem { Text = "October",Value = "10" });
              items.Add(new SelectListItem { Text = "November",Value = "11" });
              items.Add(new SelectListItem { Text = "December",Value = "12" });

                      
              ViewBag.MonthData = items;




            return View(C1.GetCalendarData(id));
        }

    }
}
