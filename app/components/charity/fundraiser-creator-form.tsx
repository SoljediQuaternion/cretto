"use client"

import { uploadToS3 } from "@/actions/upload-to-s3";
import { useState } from "react";

export const FundraiserCreatorForm = () => {

    const [file, setFile] = useState<File>(); 
    const [fileName, setFileName] = useState(""); 

    const handleFileUpload = async (event: any) => {
        event.preventDefault();
        console.log("BUTTON CLICKED"); 
        if(file){
            const fileBuffer = Buffer.from(await file.arrayBuffer()); 
            const res = await uploadToS3(fileBuffer.toString('utf-8'), fileName); 
            console.log(res); 
        }
    }

    return(
        <div>
            <div>
                <label className="border-black"> 
                    Enter file here
                    <input className="border-black" type="file" onChange={(event)=>{if(event.target.files) setFile(event.target.files[0])}}></input>
                </label>
            </div>
            <div>
                <label className="border-black"> 
                    Enter fileName here
                    <input className="border-black" type="text" onChange={(event)=>{setFileName(event.target.value)}}></input>
                </label>
            </div>
            <button onClick={handleFileUpload}>Submit</button>
        </div>
    )
}