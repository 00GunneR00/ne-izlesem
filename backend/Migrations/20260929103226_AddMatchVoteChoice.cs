using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Neizlesem.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMatchVoteChoice : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Choice",
                table: "GroupMatchVotes",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Choice",
                table: "GroupMatchVotes");
        }
    }
}
