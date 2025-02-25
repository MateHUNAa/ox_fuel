import { useExitListener } from '@/hooks/useExitListener';
import { useState } from 'react'
import { debugData } from './utils/debugData';
import { Station } from './types/station';
import useNuiEvent from './hooks/useNuiEvent';
import Dashboard from './components/Dashboard';
import Profit from './components/Profit';

enum Pages {
  "dashboard",
  "profit"
}

const pages: Record<Pages, (station: Station) => JSX.Element> = {
  [Pages.dashboard]: (station: Station) => <Dashboard Station={station} />,
  [Pages.profit]: (station: Station) => <Profit Station={station} />
}

function App() {
  const [visible, setVisibility] = useState<boolean>(false)
  const [page, setPage] = useState<Pages>(Pages.dashboard)
  const [station, setStation] = useState<Station>()
  useExitListener(setVisibility)

  useNuiEvent("open", (data: Station) => {
    setStation(data)
    setVisibility(true)
  })

  useNuiEvent("visibility", (data: boolean) => setVisibility(data))

  return (
    <div className="nem-kijelolheto App">
      {(visible && station) && (
        <div>
          <div className='w3-animate-opacity Main'>

            {/* Navbar */}
            <button className='NavBarBtStock' onClick={() => setPage(Pages["dashboard" as keyof typeof Pages])}>
              Készlet
            </button>
            <button className='NavBarBtProfit' onClick={() => setPage(Pages["profit" as keyof typeof Pages])}>
              Bevétel
            </button>


            {/* Page Selector */}
            <div>
              {pages[page](station)}

            </div>

          </div>
        </div>
      )}
    </div>
  )
}
debugData([
  {
    action: "open",
    data: {
      Fuels: [
        {
          fuel: 30,
          type: "diesel"
        },
        {
          fuel: 60,
          type: "gas"
        },
        {
          fuel: 80,
          type: "electric"
        }
      ],
      income: 817374,
      stationName: "Test Station",
      tax: 20
    } as Station
  }
])

export default App
