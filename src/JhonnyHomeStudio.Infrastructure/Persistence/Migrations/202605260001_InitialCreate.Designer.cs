using JhonnyHomeStudio.Infrastructure.Persistence.Configurations;
using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JhonnyHomeStudio.Infrastructure.Persistence.Migrations;

[DbContext(typeof(JhonnyHomeStudioDbContext))]
[Migration("202605260001_InitialCreate")]
partial class InitialCreate
{
    protected override void BuildTargetModel(ModelBuilder modelBuilder)
    {
        JhonnyHomeStudioModelConfiguration.Configure(modelBuilder);
        modelBuilder.HasAnnotation("ProductVersion", "8.0.10");
    }
}