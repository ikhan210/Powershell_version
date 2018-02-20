// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Routing.Constraints;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace mvc
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddMvc();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
            }

            app.UseStaticFiles();

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Home}/{action=Index}/{id?}");
                routes.MapRoute(
                    name: "redirect",
                    template: "Redirect/{count?}",
                    defaults: new {controller = "Redirect", action = "Index"});
                routes.MapRoute(
                    name: "delay",
                    template: "Delay/{seconds?}",
                    defaults: new {controller = "Delay", action = "Index"});
                routes.MapRoute(
                    name: "post",
                    template: "Post",
                    defaults: new {controller = "Get", action = "Index"},
                    constraints: new RouteValueDictionary(new { httpMethod = new HttpMethodRouteConstraint("POST") }));
                routes.MapRoute(
                    name: "put",
                    template: "Put",
                    defaults: new {controller = "Get", action = "Index"},
                    constraints: new RouteValueDictionary(new { httpMethod = new HttpMethodRouteConstraint("PUT") }));
                routes.MapRoute(
                    name: "patch",
                    template: "Patch",
                    defaults: new {controller = "Get", action = "Index"},
                    constraints: new RouteValueDictionary(new { httpMethod = new HttpMethodRouteConstraint("PATCH") }));
                routes.MapRoute(
                    name: "delete",
                    template: "Delete",
                    defaults: new {controller = "Get", action = "Index"},
                    constraints: new RouteValueDictionary(new { httpMethod = new HttpMethodRouteConstraint("DELETE") }));
            });
        }
    }
}
