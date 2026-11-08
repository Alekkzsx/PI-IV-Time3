// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

export type EmailRecipient = {
  email: string;
  name?: string;
};

export type EmailDeliveryResult = {
  success: boolean;
  provider: "smtp" | "resend" | "brevo" | "webhook" | "outbox";
  messageId?: string;
  error?: string;
  latencyMs: number;
};

export type BaseEmailInput = {
  to: string;
  subject: string;
  html: string;
  text: string;
  from?: string;
};

export type AuthOtpEmailInput = {
  to: string;
  displayName: string;
  code: string;
  expiresInSeconds: number;
  purpose?: "login" | "recovery";
};

export type WelcomeUserEmailInput = {
  to: string;
  displayName: string;
  identity: string;
  profile: "aluno" | "docente" | "admin";
  temporaryPassword?: string;
  portalUrl?: string;
};

export type ProtocolSubmittedEmailInput = {
  to: string;
  studentName: string;
  protocolCode: string;
  requestType: string;
  targetComponent?: string;
  justification: string;
  estimatedDays?: number;
};

export type ProtocolDecidedEmailInput = {
  to: string;
  studentName: string;
  protocolCode: string;
  requestType?: string;
  approved: boolean;
  decisionNote: string;
  signedBy: string;
};

export type AssignmentDeadlineEmailInput = {
  to: string;
  studentName: string;
  assignmentTitle: string;
  disciplineName: string;
  dueDate: Date | string;
  submissionUrl?: string;
};

export type GradePublishedEmailInput = {
  to: string;
  studentName: string;
  assignmentTitle: string;
  disciplineName: string;
  grade: number;
  feedback?: string;
};

export type DiagnosticEmailInput = {
  to: string;
  adminName: string;
  testId: string;
  timestamp: Date;
  details?: Record<string, unknown>;
};

export interface UnifiedEmailService {
  sendAuthOtp(input: AuthOtpEmailInput): Promise<EmailDeliveryResult>;
  sendWelcomeUser(input: WelcomeUserEmailInput): Promise<EmailDeliveryResult>;
  sendProtocolSubmitted(input: ProtocolSubmittedEmailInput): Promise<EmailDeliveryResult>;
  sendProtocolDecided(input: ProtocolDecidedEmailInput): Promise<EmailDeliveryResult>;
  sendAssignmentDeadline(input: AssignmentDeadlineEmailInput): Promise<EmailDeliveryResult>;
  sendGradePublished(input: GradePublishedEmailInput): Promise<EmailDeliveryResult>;
  sendDiagnostic(input: DiagnosticEmailInput): Promise<EmailDeliveryResult>;
  sendRaw(input: BaseEmailInput): Promise<EmailDeliveryResult>;
}
