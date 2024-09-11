"use server";

import { s3Client } from "@/aws-config";
import { GetObjectCommand, GetObjectCommandOutput, PutObjectCommand } from "@aws-sdk/client-s3";

export const uploadToS3 = async (file: String, fileName: string): Promise<boolean> => {
    const fileBuffer = Buffer.from(file, 'utf-8'); 
    const params = {
        Bucket: "my-bucket", 
        Key: fileName, 
        Body: fileBuffer,
    }

    try{
        const command = new PutObjectCommand(params); 
        await s3Client.send(command);  
        return true; 
    } catch(err){
        console.log("ERROR");
        return false; 
    }
}