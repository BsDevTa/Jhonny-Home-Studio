using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JhonnyHomeStudio.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddJwtAuthentication : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Address_Customer_CustomerId",
                table: "Address");

            migrationBuilder.DropForeignKey(
                name: "FK_AdminUser_User_UserId",
                table: "AdminUser");

            migrationBuilder.DropForeignKey(
                name: "FK_Appointment_Address_AddressId",
                table: "Appointment");

            migrationBuilder.DropForeignKey(
                name: "FK_Appointment_Customer_CustomerId",
                table: "Appointment");

            migrationBuilder.DropForeignKey(
                name: "FK_Appointment_Service_ServiceId",
                table: "Appointment");

            migrationBuilder.DropForeignKey(
                name: "FK_AppointmentStatusHistory_Appointment_AppointmentId",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropForeignKey(
                name: "FK_AppointmentStatusHistory_User_ChangedByUserId",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropForeignKey(
                name: "FK_Customer_User_UserId",
                table: "Customer");

            migrationBuilder.DropForeignKey(
                name: "FK_Service_ServiceCategory_ServiceCategoryId",
                table: "Service");

            migrationBuilder.DropForeignKey(
                name: "FK_Story_AdminUser_CreatedByAdminUserId",
                table: "Story");

            migrationBuilder.DropForeignKey(
                name: "FK_Story_Service_ServiceId",
                table: "Story");

            migrationBuilder.DropForeignKey(
                name: "FK_StoryView_Customer_CustomerId",
                table: "StoryView");

            migrationBuilder.DropForeignKey(
                name: "FK_StoryView_Story_StoryId",
                table: "StoryView");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_User_TempId1",
                table: "User");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_User_TempId2",
                table: "User");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_User_TempId3",
                table: "User");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Story_TempId1",
                table: "Story");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_ServiceCategory_TempId1",
                table: "ServiceCategory");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Service_TempId1",
                table: "Service");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Service_TempId2",
                table: "Service");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Customer_TempId1",
                table: "Customer");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Customer_TempId2",
                table: "Customer");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Customer_TempId3",
                table: "Customer");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Appointment_TempId1",
                table: "Appointment");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_AdminUser_TempId1",
                table: "AdminUser");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Address_TempId1",
                table: "Address");

            migrationBuilder.DropColumn(
                name: "TempId1",
                table: "User");

            migrationBuilder.DropColumn(
                name: "TempId2",
                table: "User");

            migrationBuilder.DropColumn(
                name: "TempId1",
                table: "Service");

            migrationBuilder.DropColumn(
                name: "TempId1",
                table: "Customer");

            migrationBuilder.DropColumn(
                name: "TempId2",
                table: "Customer");

            migrationBuilder.RenameTable(
                name: "User",
                newName: "Users");

            migrationBuilder.RenameTable(
                name: "StoryView",
                newName: "StoryViews");

            migrationBuilder.RenameTable(
                name: "Story",
                newName: "Stories");

            migrationBuilder.RenameTable(
                name: "ServiceCategory",
                newName: "ServiceCategories");

            migrationBuilder.RenameTable(
                name: "Service",
                newName: "Services");

            migrationBuilder.RenameTable(
                name: "Customer",
                newName: "Customers");

            migrationBuilder.RenameTable(
                name: "Appointment",
                newName: "Appointments");

            migrationBuilder.RenameTable(
                name: "AdminUser",
                newName: "AdminUsers");

            migrationBuilder.RenameTable(
                name: "Address",
                newName: "Addresses");

            migrationBuilder.RenameColumn(
                name: "TempId3",
                table: "Users",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_User_Email",
                table: "Users",
                newName: "IX_Users_Email");

            migrationBuilder.RenameIndex(
                name: "IX_StoryView_StoryId_CustomerId",
                table: "StoryViews",
                newName: "IX_StoryViews_StoryId_CustomerId");

            migrationBuilder.RenameColumn(
                name: "TempId1",
                table: "Stories",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "TempId1",
                table: "ServiceCategories",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_ServiceCategory_Name",
                table: "ServiceCategories",
                newName: "IX_ServiceCategories_Name");

            migrationBuilder.RenameColumn(
                name: "TempId2",
                table: "Services",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "TempId3",
                table: "Customers",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_Customer_UserId",
                table: "Customers",
                newName: "IX_Customers_UserId");

            migrationBuilder.RenameColumn(
                name: "TempId1",
                table: "Appointments",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "TempId1",
                table: "AdminUsers",
                newName: "Id");

            migrationBuilder.RenameIndex(
                name: "IX_AdminUser_UserId",
                table: "AdminUsers",
                newName: "IX_AdminUsers_UserId");

            migrationBuilder.RenameColumn(
                name: "TempId1",
                table: "Addresses",
                newName: "Id");

            migrationBuilder.AddColumn<Guid>(
                name: "Id",
                table: "AppointmentStatusHistory",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<DateTime>(
                name: "ChangedAtUtc",
                table: "AppointmentStatusHistory",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "AppointmentStatusHistory",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "AppointmentStatusHistory",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "Id",
                table: "StoryViews",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "StoryViews",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "StoryViews",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ViewedAtUtc",
                table: "StoryViews",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Stories",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "ExpiresAtUtc",
                table: "Stories",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Stories",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "SortOrder",
                table: "Stories",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "StartsAtUtc",
                table: "Stories",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Stories",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "ServiceCategories",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "ServiceCategories",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "ServiceCategories",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Services",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "EstimatedDurationMinutes",
                table: "Services",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Services",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Services",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "BirthDate",
                table: "Customers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Customers",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Customers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Appointments",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "EstimatedDurationMinutesSnapshot",
                table: "Appointments",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledAtUtc",
                table: "Appointments",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Appointments",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "AdminUsers",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "AdminUsers",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Addresses",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsDefault",
                table: "Addresses",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Addresses",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_AppointmentStatusHistory",
                table: "AppointmentStatusHistory",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Users",
                table: "Users",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_StoryViews",
                table: "StoryViews",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Stories",
                table: "Stories",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ServiceCategories",
                table: "ServiceCategories",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Services",
                table: "Services",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Customers",
                table: "Customers",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Appointments",
                table: "Appointments",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_AdminUsers",
                table: "AdminUsers",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Addresses",
                table: "Addresses",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_AppointmentStatusHistory_AppointmentId",
                table: "AppointmentStatusHistory",
                column: "AppointmentId");

            migrationBuilder.CreateIndex(
                name: "IX_AppointmentStatusHistory_ChangedByUserId",
                table: "AppointmentStatusHistory",
                column: "ChangedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_StoryViews_CustomerId",
                table: "StoryViews",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_Stories_CreatedByAdminUserId",
                table: "Stories",
                column: "CreatedByAdminUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Stories_ServiceId",
                table: "Stories",
                column: "ServiceId");

            migrationBuilder.CreateIndex(
                name: "IX_Services_ServiceCategoryId",
                table: "Services",
                column: "ServiceCategoryId");

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
                name: "IX_Addresses_CustomerId",
                table: "Addresses",
                column: "CustomerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Addresses_Customers_CustomerId",
                table: "Addresses",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AdminUsers_Users_UserId",
                table: "AdminUsers",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Appointments_Addresses_AddressId",
                table: "Appointments",
                column: "AddressId",
                principalTable: "Addresses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Appointments_Customers_CustomerId",
                table: "Appointments",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Appointments_Services_ServiceId",
                table: "Appointments",
                column: "ServiceId",
                principalTable: "Services",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_AppointmentStatusHistory_Appointments_AppointmentId",
                table: "AppointmentStatusHistory",
                column: "AppointmentId",
                principalTable: "Appointments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AppointmentStatusHistory_Users_ChangedByUserId",
                table: "AppointmentStatusHistory",
                column: "ChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Customers_Users_UserId",
                table: "Customers",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Services_ServiceCategories_ServiceCategoryId",
                table: "Services",
                column: "ServiceCategoryId",
                principalTable: "ServiceCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Stories_AdminUsers_CreatedByAdminUserId",
                table: "Stories",
                column: "CreatedByAdminUserId",
                principalTable: "AdminUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Stories_Services_ServiceId",
                table: "Stories",
                column: "ServiceId",
                principalTable: "Services",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_StoryViews_Customers_CustomerId",
                table: "StoryViews",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_StoryViews_Stories_StoryId",
                table: "StoryViews",
                column: "StoryId",
                principalTable: "Stories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Addresses_Customers_CustomerId",
                table: "Addresses");

            migrationBuilder.DropForeignKey(
                name: "FK_AdminUsers_Users_UserId",
                table: "AdminUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_Appointments_Addresses_AddressId",
                table: "Appointments");

            migrationBuilder.DropForeignKey(
                name: "FK_Appointments_Customers_CustomerId",
                table: "Appointments");

            migrationBuilder.DropForeignKey(
                name: "FK_Appointments_Services_ServiceId",
                table: "Appointments");

            migrationBuilder.DropForeignKey(
                name: "FK_AppointmentStatusHistory_Appointments_AppointmentId",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropForeignKey(
                name: "FK_AppointmentStatusHistory_Users_ChangedByUserId",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropForeignKey(
                name: "FK_Customers_Users_UserId",
                table: "Customers");

            migrationBuilder.DropForeignKey(
                name: "FK_Services_ServiceCategories_ServiceCategoryId",
                table: "Services");

            migrationBuilder.DropForeignKey(
                name: "FK_Stories_AdminUsers_CreatedByAdminUserId",
                table: "Stories");

            migrationBuilder.DropForeignKey(
                name: "FK_Stories_Services_ServiceId",
                table: "Stories");

            migrationBuilder.DropForeignKey(
                name: "FK_StoryViews_Customers_CustomerId",
                table: "StoryViews");

            migrationBuilder.DropForeignKey(
                name: "FK_StoryViews_Stories_StoryId",
                table: "StoryViews");

            migrationBuilder.DropPrimaryKey(
                name: "PK_AppointmentStatusHistory",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropIndex(
                name: "IX_AppointmentStatusHistory_AppointmentId",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropIndex(
                name: "IX_AppointmentStatusHistory_ChangedByUserId",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Users",
                table: "Users");

            migrationBuilder.DropPrimaryKey(
                name: "PK_StoryViews",
                table: "StoryViews");

            migrationBuilder.DropIndex(
                name: "IX_StoryViews_CustomerId",
                table: "StoryViews");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Stories",
                table: "Stories");

            migrationBuilder.DropIndex(
                name: "IX_Stories_CreatedByAdminUserId",
                table: "Stories");

            migrationBuilder.DropIndex(
                name: "IX_Stories_ServiceId",
                table: "Stories");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Services",
                table: "Services");

            migrationBuilder.DropIndex(
                name: "IX_Services_ServiceCategoryId",
                table: "Services");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ServiceCategories",
                table: "ServiceCategories");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Customers",
                table: "Customers");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Appointments",
                table: "Appointments");

            migrationBuilder.DropIndex(
                name: "IX_Appointments_AddressId",
                table: "Appointments");

            migrationBuilder.DropIndex(
                name: "IX_Appointments_CustomerId",
                table: "Appointments");

            migrationBuilder.DropIndex(
                name: "IX_Appointments_ServiceId",
                table: "Appointments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_AdminUsers",
                table: "AdminUsers");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Addresses",
                table: "Addresses");

            migrationBuilder.DropIndex(
                name: "IX_Addresses_CustomerId",
                table: "Addresses");

            migrationBuilder.DropColumn(
                name: "Id",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropColumn(
                name: "ChangedAtUtc",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "AppointmentStatusHistory");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Id",
                table: "StoryViews");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "StoryViews");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "StoryViews");

            migrationBuilder.DropColumn(
                name: "ViewedAtUtc",
                table: "StoryViews");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Stories");

            migrationBuilder.DropColumn(
                name: "ExpiresAtUtc",
                table: "Stories");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Stories");

            migrationBuilder.DropColumn(
                name: "SortOrder",
                table: "Stories");

            migrationBuilder.DropColumn(
                name: "StartsAtUtc",
                table: "Stories");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Stories");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "EstimatedDurationMinutes",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "ServiceCategories");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "ServiceCategories");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "ServiceCategories");

            migrationBuilder.DropColumn(
                name: "BirthDate",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "EstimatedDurationMinutesSnapshot",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "ScheduledAtUtc",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "AdminUsers");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "AdminUsers");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Addresses");

            migrationBuilder.DropColumn(
                name: "IsDefault",
                table: "Addresses");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Addresses");

            migrationBuilder.RenameTable(
                name: "Users",
                newName: "User");

            migrationBuilder.RenameTable(
                name: "StoryViews",
                newName: "StoryView");

            migrationBuilder.RenameTable(
                name: "Stories",
                newName: "Story");

            migrationBuilder.RenameTable(
                name: "Services",
                newName: "Service");

            migrationBuilder.RenameTable(
                name: "ServiceCategories",
                newName: "ServiceCategory");

            migrationBuilder.RenameTable(
                name: "Customers",
                newName: "Customer");

            migrationBuilder.RenameTable(
                name: "Appointments",
                newName: "Appointment");

            migrationBuilder.RenameTable(
                name: "AdminUsers",
                newName: "AdminUser");

            migrationBuilder.RenameTable(
                name: "Addresses",
                newName: "Address");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "User",
                newName: "TempId3");

            migrationBuilder.RenameIndex(
                name: "IX_Users_Email",
                table: "User",
                newName: "IX_User_Email");

            migrationBuilder.RenameIndex(
                name: "IX_StoryViews_StoryId_CustomerId",
                table: "StoryView",
                newName: "IX_StoryView_StoryId_CustomerId");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Story",
                newName: "TempId1");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Service",
                newName: "TempId2");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "ServiceCategory",
                newName: "TempId1");

            migrationBuilder.RenameIndex(
                name: "IX_ServiceCategories_Name",
                table: "ServiceCategory",
                newName: "IX_ServiceCategory_Name");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Customer",
                newName: "TempId3");

            migrationBuilder.RenameIndex(
                name: "IX_Customers_UserId",
                table: "Customer",
                newName: "IX_Customer_UserId");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Appointment",
                newName: "TempId1");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "AdminUser",
                newName: "TempId1");

            migrationBuilder.RenameIndex(
                name: "IX_AdminUsers_UserId",
                table: "AdminUser",
                newName: "IX_AdminUser_UserId");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Address",
                newName: "TempId1");

            migrationBuilder.AddColumn<Guid>(
                name: "TempId1",
                table: "User",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "TempId2",
                table: "User",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "TempId1",
                table: "Service",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "TempId1",
                table: "Customer",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "TempId2",
                table: "Customer",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddUniqueConstraint(
                name: "AK_User_TempId1",
                table: "User",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_User_TempId2",
                table: "User",
                column: "TempId2");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_User_TempId3",
                table: "User",
                column: "TempId3");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Story_TempId1",
                table: "Story",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Service_TempId1",
                table: "Service",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Service_TempId2",
                table: "Service",
                column: "TempId2");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_ServiceCategory_TempId1",
                table: "ServiceCategory",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Customer_TempId1",
                table: "Customer",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Customer_TempId2",
                table: "Customer",
                column: "TempId2");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Customer_TempId3",
                table: "Customer",
                column: "TempId3");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Appointment_TempId1",
                table: "Appointment",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_AdminUser_TempId1",
                table: "AdminUser",
                column: "TempId1");

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Address_TempId1",
                table: "Address",
                column: "TempId1");

            migrationBuilder.AddForeignKey(
                name: "FK_Address_Customer_CustomerId",
                table: "Address",
                column: "CustomerId",
                principalTable: "Customer",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AdminUser_User_UserId",
                table: "AdminUser",
                column: "UserId",
                principalTable: "User",
                principalColumn: "TempId2",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Appointment_Address_AddressId",
                table: "Appointment",
                column: "AddressId",
                principalTable: "Address",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Appointment_Customer_CustomerId",
                table: "Appointment",
                column: "CustomerId",
                principalTable: "Customer",
                principalColumn: "TempId2",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Appointment_Service_ServiceId",
                table: "Appointment",
                column: "ServiceId",
                principalTable: "Service",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_AppointmentStatusHistory_Appointment_AppointmentId",
                table: "AppointmentStatusHistory",
                column: "AppointmentId",
                principalTable: "Appointment",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AppointmentStatusHistory_User_ChangedByUserId",
                table: "AppointmentStatusHistory",
                column: "ChangedByUserId",
                principalTable: "User",
                principalColumn: "TempId3",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Customer_User_UserId",
                table: "Customer",
                column: "UserId",
                principalTable: "User",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Service_ServiceCategory_ServiceCategoryId",
                table: "Service",
                column: "ServiceCategoryId",
                principalTable: "ServiceCategory",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Story_AdminUser_CreatedByAdminUserId",
                table: "Story",
                column: "CreatedByAdminUserId",
                principalTable: "AdminUser",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Story_Service_ServiceId",
                table: "Story",
                column: "ServiceId",
                principalTable: "Service",
                principalColumn: "TempId2",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_StoryView_Customer_CustomerId",
                table: "StoryView",
                column: "CustomerId",
                principalTable: "Customer",
                principalColumn: "TempId3",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_StoryView_Story_StoryId",
                table: "StoryView",
                column: "StoryId",
                principalTable: "Story",
                principalColumn: "TempId1",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
