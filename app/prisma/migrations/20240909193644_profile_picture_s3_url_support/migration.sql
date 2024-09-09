/*
  Warnings:

  - Added the required column `profilePicture` to the `Fundraiser_Creator` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Fundraiser_Creator" ADD COLUMN     "profilePicture" TEXT NOT NULL;
