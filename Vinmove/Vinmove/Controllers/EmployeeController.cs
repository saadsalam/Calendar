using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Vinmove.Models;

namespace Vinmove.Controllers
{
    public class EmployeeController : Controller
    {
        //
        // GET: /Employee/

        public ActionResult Details(int id)
        {
            Employee employee = new Employee();
            //{
               // EmployeeId = 101,
               // Name = "John",
                //Gender = "Male",
               // City = "London"
              // GetEmployeebyId(1);
            //};

            return View(employee.GetEmployeebyId(id));
        }



        public ActionResult Index()
        {
            Employee employee = new Employee();
            //{
            // EmployeeId = 101,
            // Name = "John",
            //Gender = "Male",
            // City = "London"
            // GetEmployeebyId(1);
            //};

          return View(employee.GetEmployees());
        }
        [HttpGet]
       
        public ActionResult Create()
        {

            return View();
        }


        public void create(string FullName, string Division, int Extension, string Phone, string Designation, int DivisonSortOrder, int SortOrder, string Recordstatus)
        {
            Employee emp = new Employee();
            emp.FullName=FullName;
            emp.Division=Division; 
            emp.Extension=Extension; 
            emp.Phone=Phone; 
            emp.Designation=Designation; 
            emp.DivisonSortOrder=DivisonSortOrder;
            emp.SortOrder=SortOrder;
            emp.Recordstatus = Recordstatus;

            emp.SaveEmployee(emp);        
         
        }

    }
}