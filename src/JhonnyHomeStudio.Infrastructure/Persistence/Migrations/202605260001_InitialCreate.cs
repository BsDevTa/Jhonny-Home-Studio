using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JhonnyHomeStudio.Infrastructure.Persistence.Migrations;

public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "ServiceCategories",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                Description = table.Column<string>(type: "character varying(400)", maxLength: 400, nullable: true),
                IsActive = table.Column<bool>(type: "boolean", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_ServiceCategories", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Users",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                FullName = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                Email = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                PasswordHash = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                Phone = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                Role = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                IsActive = table.Column<bool>(type: "boolean", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Users", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Services",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                ServiceCategoryId = table.Column<Guid>(type: "uuid", nullable: false),
                Name = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                Price = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                EstimatedDurationMinutes = table.Column<int>(type: "integer", nullable: false),
                ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                IsActive = table.Column<bool>(type: "boolean", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Services", x => x.Id);
                table.ForeignKey(
                    name: "FK_Services_ServiceCategories_ServiceCategoryId",
                    column: x => x.ServiceCategoryId,
                    principalTable: "ServiceCategories",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateTable(
            name: "Customers",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                UserId = table.Column<Guid>(type: "uuid", nullable: false),
                DocumentNumber = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                BirthDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Customers", x => x.Id);
                table.ForeignKey(
                    name: "FK_Customers_Users_UserId",
                    column: x => x.UserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "AdminUsers",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                UserId = table.Column<Guid>(type: "uuid", nullable: false),
                Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_AdminUsers", x => x.Id);
                table.ForeignKey(
                    name: "FK_AdminUsers_Users_UserId",
                    column: x => x.UserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "Addresses",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                CustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                Street = table.Column<string>(type: "character varying(220)", maxLength: 220, nullable: false),
                Number = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                Neighborhood = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                City = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                State = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                ZipCode = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                Complement = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                ReferencePoint = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                IsDefault = table.Column<bool>(type: "boolean", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Addresses", x => x.Id);
                table.ForeignKey(
                    name: "FK_Addresses_Customers_CustomerId",
                    column: x => x.CustomerId,
                    principalTable: "Customers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "Appointments",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                CustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                ServiceId = table.Column<Guid>(type: "uuid", nullable: false),
                AddressId = table.Column<Guid>(type: "uuid", nullable: false),
                ScheduledAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                ServicePriceSnapshot = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                EstimatedDurationMinutesSnapshot = table.Column<int>(type: "integer", nullable: false),
                Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                CustomerNotes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Appointments", x => x.Id);
                table.ForeignKey(
                    name: "FK_Appointments_Addresses_AddressId",
                    column: x => x.AddressId,
                    principalTable: "Addresses",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
                table.ForeignKey(
                    name: "FK_Appointments_Customers_CustomerId",
                    column: x => x.CustomerId,
                    principalTable: "Customers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
                table.ForeignKey(
                    name: "FK_Appointments_Services_ServiceId",
                    column: x => x.ServiceId,
                    principalTable: "Services",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });

        migrationBuilder.CreateTable(
            name: "Stories",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                CreatedByAdminUserId = table.Column<Guid>(type: "uuid", nullable: false),
                ServiceId = table.Column<Guid>(type: "uuid", nullable: true),
                Title = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                ShortText = table.Column<string>(type: "character varying(280)", maxLength: 280, nullable: false),
                ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                ActionButtonText = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                ActionType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                ActionValue = table.Column<string>(type: "character varying(600)", maxLength: 600, nullable: true),
                StartsAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                ExpiresAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                IsActive = table.Column<bool>(type: "boolean", nullable: false),
                SortOrder = table.Column<int>(type: "integer", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Stories", x => x.Id);
                table.ForeignKey(
                    name: "FK_Stories_AdminUsers_CreatedByAdminUserId",
                    column: x => x.CreatedByAdminUserId,
                    principalTable: "AdminUsers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
                table.ForeignKey(
                    name: "FK_Stories_Services_ServiceId",
                    column: x => x.ServiceId,
                    principalTable: "Services",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.SetNull);
            });

        migrationBuilder.CreateTable(
            name: "AppointmentStatusHistory",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                AppointmentId = table.Column<Guid>(type: "uuid", nullable: false),
                Status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                ChangedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                Note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                ChangedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_AppointmentStatusHistory", x => x.Id);
                table.ForeignKey(
                    name: "FK_AppointmentStatusHistory_Appointments_AppointmentId",
                    column: x => x.AppointmentId,
                    principalTable: "Appointments",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
                table.ForeignKey(
                    name: "FK_AppointmentStatusHistory_Users_ChangedByUserId",
                    column: x => x.ChangedByUserId,
                    principalTable: "Users",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.SetNull);
            });

        migrationBuilder.CreateTable(
            name: "StoryViews",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                StoryId = table.Column<Guid>(type: "uuid", nullable: false),
                CustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                ViewedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_StoryViews", x => x.Id);
                table.ForeignKey(
                    name: "FK_StoryViews_Customers_CustomerId",
                    column: x => x.CustomerId,
                    principalTable: "Customers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
                table.ForeignKey(
                    name: "FK_StoryViews_Stories_StoryId",
                    column: x => x.StoryId,
                    principalTable: "Stories",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_Addresses_CustomerId",
            table: "Addresses",
            column: "CustomerId");

        migrationBuilder.CreateIndex(
            name: "IX_AdminUsers_UserId",
            table: "AdminUsers",
            column: "UserId",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_AppointmentStatusHistory_AppointmentId",
            table: "AppointmentStatusHistory",
            column: "AppointmentId");

        migrationBuilder.CreateIndex(
            name: "IX_AppointmentStatusHistory_ChangedByUserId",
            table: "AppointmentStatusHistory",
            column: "ChangedByUserId");

        migrationBuilder.CreateIndex(
            name: "IX_Appointments_AddressId",
            table: "Appointments",
            column: "AddressId");

        migrationBuilder.CreateIndex(
            name: "IX_Appointments_CustomerId",
            table: "Appointments",
            column: "CustomerId");

        migrationBuilder.CreateIndex(
            name: "IX_Appointments_ServiceId",
            table: "Appointments",
            column: "ServiceId");

        migrationBuilder.CreateIndex(
            name: "IX_Customers_UserId",
            table: "Customers",
            column: "UserId",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_ServiceCategories_Name",
            table: "ServiceCategories",
            column: "Name",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Services_ServiceCategoryId",
            table: "Services",
            column: "ServiceCategoryId");

        migrationBuilder.CreateIndex(
            name: "IX_Stories_CreatedByAdminUserId",
            table: "Stories",
            column: "CreatedByAdminUserId");

        migrationBuilder.CreateIndex(
            name: "IX_Stories_ServiceId",
            table: "Stories",
            column: "ServiceId");

        migrationBuilder.CreateIndex(
            name: "IX_StoryViews_CustomerId",
            table: "StoryViews",
            column: "CustomerId");

        migrationBuilder.CreateIndex(
            name: "IX_StoryViews_StoryId_CustomerId",
            table: "StoryViews",
            columns: new[] { "StoryId", "CustomerId" },
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Users_Email",
            table: "Users",
            column: "Email",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "AppointmentStatusHistory");
        migrationBuilder.DropTable(name: "StoryViews");
        migrationBuilder.DropTable(name: "Appointments");
        migrationBuilder.DropTable(name: "Stories");
        migrationBuilder.DropTable(name: "Addresses");
        migrationBuilder.DropTable(name: "AdminUsers");
        migrationBuilder.DropTable(name: "Services");
        migrationBuilder.DropTable(name: "Customers");
        migrationBuilder.DropTable(name: "Users");
        migrationBuilder.DropTable(name: "ServiceCategories");
    }
}