using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Neizlesem.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationClear : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "DismissedBySender",
                table: "SuggestionRecipients",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "MatchesClearedAt",
                table: "GroupMembers",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DismissedBySender",
                table: "SuggestionRecipients");

            migrationBuilder.DropColumn(
                name: "MatchesClearedAt",
                table: "GroupMembers");
        }
    }
}
