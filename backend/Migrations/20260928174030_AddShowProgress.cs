using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Neizlesem.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddShowProgress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CurrentEpisode",
                table: "LibraryEntries",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CurrentSeason",
                table: "LibraryEntries",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CurrentEpisode",
                table: "LibraryEntries");

            migrationBuilder.DropColumn(
                name: "CurrentSeason",
                table: "LibraryEntries");
        }
    }
}
