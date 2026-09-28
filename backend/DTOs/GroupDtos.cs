namespace Neizlesem.Api.DTOs;

public record GroupDto(int Id, string Name, int OwnerId, List<UserSummaryDto> Members);

public record CreateGroupRequest(int OwnerId, string Name, List<int> MemberUserIds);
