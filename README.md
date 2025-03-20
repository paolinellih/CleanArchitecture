# Clean Architecture .NET 8 Web API with MongoDB - Quick Start Guide

![Clean Architecture C#](https://github.com/paolinellih/CleanArchitecture/blob/main/CleanArchitectureCSharp.png)

## Imagine you could start a Clean Architecture .NET API with MongoDB in seconds?

This guide shows you how to quickly get up and running with a Clean Architecture in .NET 8, using MongoDB as the database. With just a few simple commands, you'll have a fully working web API for CRUD (Create, Read, Update, Delete) operations on a "Student" model. 🚀

### What You Need:
- PowerShell (for running the script)
- Visual Studio Code (for editing the code)
- Docker (for running the application in containers)

### Step-by-Step Instructions:

1. **Create a Project Folder**
   Create a folder for your project and place the PowerShell script (`CreateCleanArchitectureProjectStructure.ps1`) inside it.

2. **Run the PowerShell Script**  
   Open PowerShell, navigate to your project folder, and run the following command:
   ```powershell
   .\CreateCleanArchitectureProjectStructure.ps1
   ```

3. **Open the Project in Visual Studio Code**  
   Once the project structure is created, simply type the following to open the project in VS Code:
   ```bash
   code .
   ```

4. **Build and Start with Docker**  
   In the VS Code terminal, run the following to build and launch the application using Docker:
   ```bash
   docker-compose up --build
   ```

Just access http://localhost:5000/swagger and 'voilà'

---

### What's Happening in the Background?

The PowerShell script automates the following tasks:

- **Creates the .NET solution and projects**  
  It sets up the Clean Architecture structure with the necessary layers for your application:
  - **API Layer** (`Web API`)
  - **Application Layer** (`Services`, `UseCases`)
  - **Domain Layer** (`Entities`, `Repositories`)
  - **Infrastructure Layer** (`MongoDB`, `Repositories`)

- **Installs the required dependencies**  
  The script adds necessary NuGet packages, like:
  - `MongoDB.Driver` for MongoDB integration
  - `Moq` for testing purposes
  - `Microsoft.Extensions.Configuration` for configuration management

- **Creates MongoDB models and repositories**  
  It automatically generates the `MongoDbContext` and repository implementations, allowing for quick interaction with MongoDB.

- **Sets up a Dockerized environment**  
  The script also creates `Dockerfile` and `docker-compose.yml`, so your application can be built and run in containers. With Docker, you can ensure your application is environment-agnostic and easy to deploy.

---

### Enjoy Your API! 🎉

Once you've completed the steps above, you'll have:
- A fully functional .NET 8 Clean Architecture Web API
- A "Student" model with CRUD functionality connected to MongoDB
- A Dockerized environment for easy deployment

This is a simple, repeatable, and customizable setup. It provides a solid foundation for building scalable, maintainable APIs with .NET and MongoDB.

---

### Let’s Connect!

If you found this useful, feel free to connect with me on LinkedIn or drop a message if you have any questions or need further assistance.

Happy coding! 🎉
