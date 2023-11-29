import React, { useEffect, useState } from 'react';
import Urbit from '@urbit/http-api';
// import { AppTile } from './components/AppTile';

const api = new Urbit('', '', window.desk);
api.ship = 'zod'  //window.ship;
console.log('api.ship', api.ship);

export function App() {
  const [inputValue, setInputValue] = useState("");

  const onChangeInput = (e: React.FormEvent<HTMLInputElement>) => {
    setInputValue(e.currentTarget.value);
  };

  // useEffect(() => {
  //   const subscribe = () => {
  //     try {
  //       console.log('subscribing...');
  //       const res = api.subscribe({
  //         app: "volt",
  //         path: "/all",
  //         event: (e) => console.log('New poke event', e),
  //         err: () => console.log("Subscription rejected"),
  //         quit: () => console.log("Kicked from subscription"),
  //       });
  //       console.log('subscribed', res);
  //     } catch (e) {
  //       console.log("Subscription failed", e);
  //     }
  //   };
  //   subscribe()
  // }, [])

  // const setProvider = async () => {
  //   try {
  //     const res = await api.poke({
  //       app: "volt",
  //       mark: "volt-command",
  //       json: {"set-provider": "~zod"},
  //       onSuccess: () => console.log('success'),
  //       onError: () => console.log('failure'),
  //     });
  //     console.log(res);
  //   } catch (e) {
  //     console.error(e);
  //   }
  // }

  const setProvider = async () => {
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"set-provider": "~zod"},
        onSuccess: () => console.log('success'),
        onError: () => console.log('failure'),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  }

  return (
    <main className="flex items-center justify-center min-h-screen">
      <div className="max-w-md space-y-6 py-20">
        <button className='border border-gray-400 rounded-md mr-2' onClick={setProvider}>Set provider</button>
        <input
          className='border border-gray-400 rounded-md p-2'
          type="text"
          name="name"
          onChange={onChangeInput}
          autoComplete="off"
          value={inputValue}
        />
      </div>
    </main>
  );
}
