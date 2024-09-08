-- CreateEnum
CREATE TYPE "ApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'SLASHED');

-- CreateTable
CREATE TABLE "Approvers" (
    "id" SERIAL NOT NULL,
    "approverAddress" TEXT NOT NULL,
    "aptStaked" BIGINT NOT NULL,
    "lastWithdrawalTimestamp" TIMESTAMP(3) NOT NULL,
    "approvalStatus" "ApprovalStatus" NOT NULL,

    CONSTRAINT "Approvers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Approvers_approverAddress_key" ON "Approvers"("approverAddress");
