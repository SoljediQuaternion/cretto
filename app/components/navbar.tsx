"use client"
import { useWallet, Wallet } from "@aptos-labs/wallet-adapter-react"
import Link from "next/link";
import { PetraWalletName } from "petra-plugin-wallet-adapter";

export const Navbar = () => {
    
    const wallet = useWallet(); 
    
    const getShortAddress = (address?: string) => {
        if(!address){
            return; 
        }
        return `${address.slice(0,8)}...`; 
    }

    return(
        <div>            
            <nav className="py-4 px-10">
                <div className="flex justify-between items-center">
                    <div className="flex items-center">
                        <h1>Logo</h1>
                    </div>
                    <div className="flex justify-center items-center space-x-8">
                        <Link href="/auction">
                            Auction
                        </Link>
                        <Link href="/grants">
                            Grants
                        </Link>
                        <Link href="/charity">
                            Charity
                        </Link>
                    </div>
                    <div
                        className="bg-black text-white px-2 py-2 rounded-md"
                    >
                        {
                            wallet.connected?
                                <button
                                    onClick={()=>{wallet.disconnect()}}
                                >
                                {getShortAddress(wallet.account?.address) ?? ""}
                                </button>:
                                <button                                 
                                    onClick={() => {wallet.connect(PetraWalletName)}}
                                >
                                    SignIn
                                </button>
                        }
                    </div>
                </div>
            </nav>
            <hr></hr>
        </div>    
    )
}