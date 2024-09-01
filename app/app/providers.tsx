"use client"

import { AptosWalletAdapterProvider } from "@aptos-labs/wallet-adapter-react"
import { PetraWallet } from "petra-plugin-wallet-adapter"

export const Providers = ({children}: {children: React.ReactNode}) => {
    const wallets = [new PetraWallet()]; 
    return(
        <AptosWalletAdapterProvider plugins={wallets} autoConnect={true}>
            {children}
        </AptosWalletAdapterProvider>
    )
}