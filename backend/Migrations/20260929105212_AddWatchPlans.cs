using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Neizlesem.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWatchPlans : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WatchPlans",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CreatorId = table.Column<int>(type: "integer", nullable: false),
                    TitleId = table.Column<int>(type: "integer", nullable: false),
                    GroupId = table.Column<int>(type: "integer", nullable: true),
                    ScheduledAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WatchPlans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WatchPlans_Groups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "Groups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_WatchPlans_Titles_TitleId",
                        column: x => x.TitleId,
                        principalTable: "Titles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WatchPlans_Users_CreatorId",
                        column: x => x.CreatorId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PlanAttendees",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PlanId = table.Column<int>(type: "integer", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    Response = table.Column<int>(type: "integer", nullable: false),
                    RespondedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Outcome = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PlanAttendees", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PlanAttendees_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PlanAttendees_WatchPlans_PlanId",
                        column: x => x.PlanId,
                        principalTable: "WatchPlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PlanAttendees_PlanId_UserId",
                table: "PlanAttendees",
                columns: new[] { "PlanId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PlanAttendees_UserId",
                table: "PlanAttendees",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_WatchPlans_CreatorId",
                table: "WatchPlans",
                column: "CreatorId");

            migrationBuilder.CreateIndex(
                name: "IX_WatchPlans_GroupId",
                table: "WatchPlans",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_WatchPlans_ScheduledAt",
                table: "WatchPlans",
                column: "ScheduledAt");

            migrationBuilder.CreateIndex(
                name: "IX_WatchPlans_TitleId",
                table: "WatchPlans",
                column: "TitleId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PlanAttendees");

            migrationBuilder.DropTable(
                name: "WatchPlans");
        }
    }
}
