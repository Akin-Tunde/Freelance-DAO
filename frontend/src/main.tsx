// frontend/src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.tsx';
import './index.css';

// 1. Import dependencies
import { WagmiProvider, createConfig, http } from 'wagmi';
import { base, hardhat } from 'wagmi/chains'; // Import chains
import { injected } from '@wagmi/connectors'; // Import wallet connectors
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// 2. Configure wagmi
const config = createConfig({
  chains: [base, hardhat], // Add chains you want to support
  connectors: [
    injected(), // MetaMask, Rainbow, etc.
  ],
  transports: {
    [base.id]: http(),
    [hardhat.id]: http(), // For local testing
  },
});

// 3. Set up a React Query client
const queryClient = new QueryClient();

// 4. Render the app with the providers
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>
);