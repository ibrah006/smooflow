enum InvitationSendStatus {
  success,
  failed,
  // A request is already pending from this organization
  alreadyPending,
  // The requested user is already part of the organization the invitation is being sent from
  alreadyPartOfThisOrg,
}