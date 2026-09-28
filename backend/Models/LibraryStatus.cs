namespace Neizlesem.Api.Models;

public enum LibraryStatus
{
    ToWatch,
    Watched,

    /// <summary>A show in progress ("İzliyorum"); see LibraryEntry.CurrentSeason/CurrentEpisode.</summary>
    Watching,
}
