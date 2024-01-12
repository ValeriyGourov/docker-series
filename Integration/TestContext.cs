using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;

using AccountOwnerServer;

using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;

using Microsoft.Extensions.Configuration;

namespace Integration
{
	public class TestContext : IDisposable
	{
		private TestServer _server;
		public HttpClient Client { get; private set; }

		public TestContext()
		{
			SetUpClient();
		}

		private void SetUpClient()
		{
			_server = new TestServer(new WebHostBuilder()
				.UseConfiguration(new ConfigurationBuilder()
					.AddJsonFile("appsettings.json")
					.Build())
				.UseStartup<Startup>());

			Client = _server.CreateClient();
		}

		public void Dispose()
		{
			_server?.Dispose();
			Client?.Dispose();
		}
	}
}
