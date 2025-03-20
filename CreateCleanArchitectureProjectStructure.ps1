# Define Solution and Project Names
$solutionName = "CleanArchitectureProjectStructure"
$apiProject = "$solutionName.Api"
$applicationProject = "$solutionName.Application"
$domainProject = "$solutionName.Domain"
$infrastructureProject = "$solutionName.Infrastructure"
$applicationTestProject = "$solutionName.Application.Tests"  # Test project for Application layer

# Create the solution
dotnet new sln -n $solutionName

# Create Projects
dotnet new webapi -n $apiProject
dotnet new classlib -n $applicationProject
dotnet new classlib -n $domainProject
dotnet new classlib -n $infrastructureProject

# Create Test Project for Application layer
dotnet new xunit -n $applicationTestProject

# Add Projects to the Solution
dotnet sln add "$apiProject/$apiProject.csproj"
dotnet sln add "$applicationProject/$applicationProject.csproj"
dotnet sln add "$domainProject/$domainProject.csproj"
dotnet sln add "$infrastructureProject/$infrastructureProject.csproj"
dotnet sln add "$applicationTestProject/$applicationTestProject.csproj"

# Set Up Dependencies (Referencing Each Layer)
dotnet add "$apiProject/$apiProject.csproj" reference "$applicationProject/$applicationProject.csproj"
dotnet add "$applicationProject/$applicationProject.csproj" reference "$domainProject/$domainProject.csproj"
dotnet add "$infrastructureProject/$infrastructureProject.csproj" reference "$domainProject/$domainProject.csproj"
dotnet add "$applicationProject/$applicationProject.csproj" reference "$infrastructureProject/$infrastructureProject.csproj"

# Install Required Packages
dotnet add "$apiProject/$apiProject.csproj" package Microsoft.AspNetCore.Mvc.Core
dotnet add "$infrastructureProject/$infrastructureProject.csproj" package MongoDB.Driver
dotnet add "$infrastructureProject/$infrastructureProject.csproj" package Microsoft.Extensions.Configuration.Abstractions


# Add Moq to the Test Project for mocking
dotnet add "$applicationTestProject/$applicationTestProject.csproj" package Moq

# Define the folder structures
$folders = @{
    $apiProject = @("Controllers", "Middleware", "Models", "Configurations")
    $applicationProject = @("UseCases", "DTOs", "Interfaces", "Services")
    $domainProject = @("Entities", "Aggregates", "Services", "Repositories", "ValueObjects")
    $infrastructureProject = @("Persistence", "Repositories", "Configurations", "Migrations")
    $applicationTestProject = @("UnitTests")  # Folder for application layer tests
}

# Create Folders
foreach ($project in $folders.Keys) {
    foreach ($folder in $folders[$project]) {
        $path = "$project\$folder"
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }
    Write-Output "✅ Folders created for $project"
}

# Create MongoDB Model and Context in Infrastructure
New-Item -ItemType File -Force -Path "$infrastructureProject/Persistence/MongoDbContext.cs"
Set-Content -Path "$infrastructureProject/Persistence/MongoDbContext.cs" -Value @"
using MongoDB.Driver;
using Microsoft.Extensions.Configuration;
using System;

namespace $infrastructureProject.Persistence
{
    public class MongoDbContext
    {
        private readonly IMongoDatabase _database;

        public MongoDbContext(IConfiguration configuration)
        {
            string connectionString = configuration.GetConnectionString("MongoDb") 
                ?? throw new ArgumentNullException("MongoDb connection string is missing");

            var mongoUrl = new MongoUrl(connectionString);
            var client = new MongoClient(mongoUrl);
            _database = client.GetDatabase(mongoUrl.DatabaseName ?? "defaultDb");
        }

        public IMongoCollection<T> GetCollection<T>(string collectionName)
        {
            return _database.GetCollection<T>(collectionName);
        }
    }
}
"@

# Create MongoDB Repository Interface and Implementation in Infrastructure
New-Item -ItemType File -Force -Path "$infrastructureProject/Repositories/IRepository.cs"
Set-Content -Path "$infrastructureProject/Repositories/IRepository.cs" -Value @"
namespace $infrastructureProject.Repositories
{
    public interface IRepository<T>
    {
        Task<T> GetAsync(string id);
        Task<IEnumerable<T>> GetAllAsync();
        Task CreateAsync(T entity);
        Task UpdateAsync(T entity);
        Task DeleteAsync(string id);
    }
}
"@

New-Item -ItemType File -Force -Path "$infrastructureProject/Repositories/MongoRepository.cs"
Set-Content -Path "$infrastructureProject/Repositories/MongoRepository.cs" -Value @"
using MongoDB.Driver;
using $solutionName.Infrastructure.Persistence;
using $solutionName.Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace $infrastructureProject.Repositories
{
    public class MongoRepository<T> : IRepository<T> where T: BaseEntity
    {
        private readonly MongoDbContext _context;
        private readonly IMongoCollection<T> _collection;

        public MongoRepository(MongoDbContext context)
        {
            _context = context;
            _collection = _context.GetCollection<T>(typeof(T).Name);
        }

        public async Task<T> GetAsync(string id)
        {
            return await _collection.Find(x => x.Id == id).FirstOrDefaultAsync();
        }

        public async Task<IEnumerable<T>> GetAllAsync()
        {
            return await _collection.Find(Builders<T>.Filter.Empty).ToListAsync();
        }

        public async Task CreateAsync(T entity)
        {
            await _collection.InsertOneAsync(entity);
        }

        public async Task UpdateAsync(T entity)
        {
            await _collection.ReplaceOneAsync(x => x.Id == entity.Id, entity);
        }

        public async Task DeleteAsync(string id)
        {
            await _collection.DeleteOneAsync(x => x.Id == id);
        }
    }
}
"@

# Create BaseEntity Class in Domain
New-Item -ItemType File -Force -Path "$domainProject/Entities/BaseEntity.cs"
Set-Content -Path "$domainProject/Entities/BaseEntity.cs" -Value @"
namespace $domainProject.Entities
{
    public class BaseEntity
    {
        public string Id { get; set; }
    }
}
"@

# Create Student Model in Domain
New-Item -ItemType File -Force -Path "$domainProject/Entities/Student.cs"
Set-Content -Path "$domainProject/Entities/Student.cs" -Value @"
namespace $domainProject.Entities
{
    public class Student : BaseEntity
    {
        public string Name { get; set; }
        public int Age { get; set; }
        public string Email { get; set; }
    }
}
"@

# Create UseCase in Application (for CRUD functionality)
New-Item -ItemType File -Force -Path "$applicationProject/UseCases/StudentUseCase.cs"
Set-Content -Path "$applicationProject/UseCases/StudentUseCase.cs" -Value @"
using $infrastructureProject.Repositories;
using $domainProject.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace $applicationProject.UseCases
{
    public class StudentUseCase
    {
        private readonly IRepository<Student> _repository;

        public StudentUseCase(IRepository<Student> repository)
        {
            _repository = repository;
        }

        public async Task CreateStudent(Student student)
        {
            await _repository.CreateAsync(student);
        }

        public async Task<IEnumerable<Student>> GetAllStudents()
        {
            return await _repository.GetAllAsync();
        }

        public async Task<Student> GetStudentById(string id)
        {
            return await _repository.GetAsync(id);
        }

        public async Task UpdateStudent(Student student)
        {
            await _repository.UpdateAsync(student);
        }

        public async Task DeleteStudent(string id)
        {
            await _repository.DeleteAsync(id);
        }
    }
}
"@

# Create Student Controller in Api
New-Item -ItemType File -Force -Path "$apiProject/Controllers/StudentsController.cs"
Set-Content -Path "$apiProject/Controllers/StudentsController.cs" -Value @"
using $applicationProject.UseCases;
using $domainProject.Entities;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace $apiProject.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StudentsController : ControllerBase
    {
        private readonly StudentUseCase _studentUseCase;

        public StudentsController(StudentUseCase studentUseCase)
        {
            _studentUseCase = studentUseCase;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Student>>> GetAllStudents()
        {
            return Ok(await _studentUseCase.GetAllStudents());
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Student>> GetStudentById(string id)
        {
            var student = await _studentUseCase.GetStudentById(id);
            if (student == null)
                return NotFound();
            return Ok(student);
        }

        [HttpPost]
        public async Task<ActionResult> CreateStudent([FromBody] Student student)
        {
            await _studentUseCase.CreateStudent(student);
            return CreatedAtAction(nameof(GetStudentById), new { id = student.Id }, student);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateStudent(string id, [FromBody] Student student)
        {
            if (id != student.Id)
                return BadRequest();
            await _studentUseCase.UpdateStudent(student);
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStudent(string id)
        {
            await _studentUseCase.DeleteStudent(id);
            return NoContent();
        }
    }
}
"@

Write-Output "✅ CRUD functionality for Student created."

# Create Unit Test for Application Service/UseCase in Application.Tests
New-Item -ItemType File -Force -Path "$applicationTestProject/UnitTests/StudentUseCaseTests.cs"
Set-Content -Path "$applicationTestProject/UnitTests/StudentUseCaseTests.cs" -Value @"
using Moq;
using System.Threading.Tasks;
using Xunit;
using $applicationProject.UseCases;
using $infrastructureProject.Repositories;
using $domainProject.Entities;

namespace $applicationTestProject.UnitTests
{
    public class StudentUseCaseTests
    {
        private readonly Mock<IRepository<Student>> _mockRepository;
        private readonly StudentUseCase _useCase;

        public StudentUseCaseTests()
        {
            _mockRepository = new Mock<IRepository<Student>>();
            _useCase = new StudentUseCase(_mockRepository.Object);
        }

        [Fact]
        public async Task CreateStudent_ShouldAddStudent()
        {
            // Arrange
            var student = new Student { Id = "1", Name = "John", Age = 20, Email = "john@example.com" };
            _mockRepository.Setup(repo => repo.CreateAsync(It.IsAny<Student>())).Returns(Task.CompletedTask);

            // Act
            await _useCase.CreateStudent(student);

            // Assert
            _mockRepository.Verify(repo => repo.CreateAsync(It.IsAny<Student>()), Times.Once);
        }
    }
}
"@

# Modify Program.cs to use Controllers
$programCsPath = "$apiProject/Program.cs"
if (Test-Path $programCsPath) {
    Write-Host "Updating Program.cs to support Controllers..."

    # Update Program.cs content
    $programCsContent = @"
using $solutionName.Application.UseCases;
using $solutionName.Infrastructure.Persistence;
using $solutionName.Infrastructure.Repositories;


var builder = WebApplication.CreateBuilder(args);

builder.Environment.EnvironmentName = "Development";
builder.WebHost.UseUrls("http://0.0.0.0:5000"); // Bind to all IPs

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Get MongoDB connection string from appsettings.json
var mongoConnectionString = builder.Configuration.GetConnectionString("MongoDb");

// Register MongoDbContext with required connection string
builder.Services.AddSingleton<MongoDbContext>(sp => new MongoDbContext(builder.Configuration));

// Register generic repository
builder.Services.AddScoped(typeof(IRepository<>), typeof(MongoRepository<>));

// Register use cases
builder.Services.AddScoped<StudentUseCase>();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthorization();

app.MapControllers();

// Default basics up
app.MapGet("/", () => Results.Ok("API is running"));
app.MapGet("/env", () => Results.Ok($"Environment: {Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")}, MachineName: {Environment.MachineName}, ProcessorCount: {Environment.ProcessorCount}"));

app.Run();
"@

    Set-Content -Path $programCsPath -Value $programCsContent
}


# Define the path to appsettings.json
$jsonPath = "$apiProject/appsettings.json"

# Read the existing JSON file
$jsonContent = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

# Add or update the ConnectionStrings property
if (-not $jsonContent.PSObject.Properties["ConnectionStrings"]) {
    $jsonContent | Add-Member -MemberType NoteProperty -Name "ConnectionStrings" -Value @{} -Force
}

$jsonContent.ConnectionStrings.MongoDb = "mongodb://root:rootpassword@mongo:27017"

# Convert back to JSON format and save
$jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath

# Dynamically build paths for project references
$applicationProjectPath = "$applicationProject/$applicationProject.csproj"
$infrastructureProjectPath = "$infrastructureProject/$infrastructureProject.csproj"
$domainProjectPath = "$domainProject/$domainProject.csproj"
$applicationTestProjectPath = "$applicationTestProject/$applicationTestProject.csproj"

# Add references to the test project dynamically
dotnet add $applicationTestProjectPath reference $applicationProjectPath
dotnet add $applicationTestProjectPath reference $infrastructureProjectPath
dotnet add $applicationTestProjectPath reference $domainProjectPath

# Output confirmation
Write-Output "✅ References added successfully"

# Dockerize the Application
Write-Output "✅ CRUD functionality complete. Creating Dockerfile and docker-compose.yml..."

# Define the path for the Dockerfile
$dockerfilePath = "$apiProject/Dockerfile"

# Create the Dockerfile dynamically
New-Item -ItemType File -Force -Path $dockerfilePath
Set-Content -Path $dockerfilePath -Value @"
# Use .NET 8.0 SDK image for build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Set the working directory
WORKDIR /src

# Copy the entire solution
COPY . .

# Restore the dependencies for the API project
RUN dotnet restore "$apiProject/$apiProject.csproj"

# Set the working directory for the API project
WORKDIR /src/$apiProject

# Publish the application
RUN dotnet publish "$apiProject.csproj" -c Release -o /app/publish

# Use .NET 8.0 runtime image for runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

# Set the working directory in the container
WORKDIR /app

# Expose ports
EXPOSE 5000

# Copy the published application from the build stage
COPY --from=build /app/publish .

# Explicitly set the listening port for ASP.NET Core application
ENV ASPNETCORE_URLS=http://+:5000

# Set the entrypoint to run the application
ENTRYPOINT ["dotnet", "$apiProject.dll"]
"@
Write-Output "✅ Dockerfile created successfully"

# Convert the project names to lowercase for Docker image names
$apiProjectImage = $apiProject.ToLower()

# Define the path to the docker-compose.yml file
$dockerComposePath = "docker-compose.yml"

# Create the docker-compose.yml file dynamically
New-Item -ItemType File -Force -Path $dockerComposePath
Set-Content -Path $dockerComposePath -Value @"
services:
  $apiProject-api:
    image: $apiProjectImage
    build:
      context: .
      dockerfile: "$apiProject/Dockerfile"
    ports:
      - "5000:5000"
    depends_on:
      - mongo

  mongo:
    image: mongo
    container_name: mongo
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=root
      - MONGO_INITDB_ROOT_PASSWORD=rootpassword
"@

Write-Output "✅ Dockerfile and docker-compose.yml created for containerized environment."
Write-Output "🚀 Your CRUD system is ready to be built and run!"
