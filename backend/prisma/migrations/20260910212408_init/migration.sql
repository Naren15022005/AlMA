-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "avatarUrl" TEXT,
    "birthday" DATETIME,
    "fcmToken" TEXT,
    "pairCode" TEXT NOT NULL,
    "coupleId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "users_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "token" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "refresh_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "couples" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "user1Id" TEXT NOT NULL,
    "user2Id" TEXT NOT NULL,
    "anniversary" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "events" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "coupleId" TEXT NOT NULL,
    "createdById" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "startAt" DATETIME NOT NULL,
    "endAt" DATETIME,
    "category" TEXT NOT NULL DEFAULT 'DATE',
    "reminderMinutes" INTEGER,
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "events_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "events_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "memes" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "coupleId" TEXT NOT NULL,
    "uploadedBy" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "caption" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "memes_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "memes_uploadedBy_fkey" FOREIGN KEY ("uploadedBy") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "meme_reactions" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "memeId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "emoji" TEXT NOT NULL,
    CONSTRAINT "meme_reactions_memeId_fkey" FOREIGN KEY ("memeId") REFERENCES "memes" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "meme_reactions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "reminders" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "coupleId" TEXT NOT NULL,
    "createdBy" TEXT NOT NULL,
    "targetUser" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "scheduledAt" DATETIME NOT NULL,
    "recurrence" TEXT NOT NULL DEFAULT 'NONE',
    "isCompleted" BOOLEAN NOT NULL DEFAULT false,
    "completedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "reminders_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "reminders_createdBy_fkey" FOREIGN KEY ("createdBy") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "locations" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "coupleId" TEXT NOT NULL,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "recordedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "locations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "locations_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "diary_entries" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "coupleId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "title" TEXT,
    "content" TEXT NOT NULL,
    "mood" TEXT NOT NULL,
    "imageUrl" TEXT,
    "isPrivate" BOOLEAN NOT NULL DEFAULT false,
    "entryDate" DATETIME NOT NULL,
    "partnerReacted" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "diary_entries_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "diary_entries_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "game_sessions" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "coupleId" TEXT NOT NULL,
    "gameType" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'WAITING',
    "winnerId" TEXT,
    "data" TEXT NOT NULL DEFAULT '{}',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" DATETIME,
    CONSTRAINT "game_sessions_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "thoughts" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "coupleId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "tone" TEXT NOT NULL DEFAULT 'ROMANTIC',
    "deliverAt" DATETIME,
    "isDelivered" BOOLEAN NOT NULL DEFAULT false,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "readAt" DATETIME,
    "isFavorite" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "thoughts_coupleId_fkey" FOREIGN KEY ("coupleId") REFERENCES "couples" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "thoughts_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_pairCode_key" ON "users"("pairCode");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE UNIQUE INDEX "couples_user1Id_key" ON "couples"("user1Id");

-- CreateIndex
CREATE UNIQUE INDEX "couples_user2Id_key" ON "couples"("user2Id");

-- CreateIndex
CREATE INDEX "events_coupleId_startAt_idx" ON "events"("coupleId", "startAt");

-- CreateIndex
CREATE INDEX "memes_coupleId_createdAt_idx" ON "memes"("coupleId", "createdAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "meme_reactions_memeId_userId_emoji_key" ON "meme_reactions"("memeId", "userId", "emoji");

-- CreateIndex
CREATE INDEX "reminders_coupleId_scheduledAt_idx" ON "reminders"("coupleId", "scheduledAt");

-- CreateIndex
CREATE INDEX "locations_userId_recordedAt_idx" ON "locations"("userId", "recordedAt" DESC);

-- CreateIndex
CREATE INDEX "diary_entries_coupleId_entryDate_idx" ON "diary_entries"("coupleId", "entryDate" DESC);

-- CreateIndex
CREATE INDEX "game_sessions_coupleId_createdAt_idx" ON "game_sessions"("coupleId", "createdAt" DESC);

-- CreateIndex
CREATE INDEX "thoughts_coupleId_deliverAt_idx" ON "thoughts"("coupleId", "deliverAt");
