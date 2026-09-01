using JhonnyHomeStudio.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JhonnyHomeStudio.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(JhonnyHomeStudioDbContext))]
    [Migration("20260717190000_UpdateBusinessHoursToShiftSchedule")]
    public partial class UpdateBusinessHoursToShiftSchedule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE "BusinessHours"
                SET
                    "IsOpen" = CASE WHEN "DayOfWeek" BETWEEN 1 AND 6 THEN TRUE ELSE FALSE END,
                    "StartTime" = TIME '09:00:00',
                    "EndTime" = TIME '17:00:00',
                    "SlotIntervalMinutes" = 60,
                    "UpdatedAt" = NOW()
                WHERE "DayOfWeek" BETWEEN 0 AND 6;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE "BusinessHours"
                SET
                    "IsOpen" = CASE WHEN "DayOfWeek" BETWEEN 1 AND 6 THEN TRUE ELSE FALSE END,
                    "StartTime" = TIME '08:00:00',
                    "EndTime" = CASE
                        WHEN "DayOfWeek" = 6 THEN TIME '14:00:00'
                        ELSE TIME '18:00:00'
                    END,
                    "SlotIntervalMinutes" = 30,
                    "UpdatedAt" = NOW()
                WHERE "DayOfWeek" BETWEEN 0 AND 6;
                """);
        }
    }
}
