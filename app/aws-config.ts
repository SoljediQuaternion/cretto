import {S3Client} from "@aws-sdk/client-s3"; 

export const s3Client = new S3Client({
  region: process.env.AWS_REGION, 
  endpoint: "http://localhost:4566",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY ?? "test" , 
    secretAccessKey: process.env.AWS_SECRET_KEY ?? "test"
  }, 
  forcePathStyle: true
}); 
