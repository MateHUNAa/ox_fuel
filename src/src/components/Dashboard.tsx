import { FC } from 'react';
import { Station } from '@/types/station';
import { fetchNui } from '@/utils/fetchNui';

interface DashboardProps {
    Station: Station;
}

const Dashboard: FC<DashboardProps> = ({ Station }) => {
    const getHeight = (fuelPercentage: number | undefined) => {
        if (fuelPercentage === undefined) return '0px';
        return `${(fuelPercentage * 180) / 100}px`;
    };

    return (
        <div>
            <div className='w3-animate-top PageNameDiv'>
                <p className='PageNameText'>Készlet</p>
            </div>

            <div className='w3-animate-bottom FuelCirleTypes'>
                {/* Benzin */}
                <div className='GasDiv'>
                    <p className='FuelsNameText'>Benzin</p>
                    <div className="CirleDivBack">
                        <p className='FuelPerscentigText'>{Station.Fuels[1]?.fuel}%</p>
                        <div
                            className="GasCirleDiv"
                            style={{ height: getHeight(Station.Fuels[1]?.fuel) }}
                        ></div>
                    </div>
                    <button
                        onClick={() => fetchNui("start-refill", "gas")}
                        className='StockBuyBt'>Indítás</button>
                </div>

                {/* Dízel */}
                <div className='DiselDiv'>
                    <p className='FuelsNameText'>Dízel</p>
                    <div className="CirleDivBack">
                        <p className='FuelPerscentigText'>{Station.Fuels[0]?.fuel}%</p>
                        <div
                            className="DiselCirleDiv"
                            style={{ height: getHeight(Station.Fuels[0]?.fuel) }}
                        ></div>
                    </div>
                    <button
                        onClick={() => fetchNui("start-refill", "diesel")}
                        className='StockBuyBt'>Indítás</button>
                </div>

                {/* Elektromos */}
                <div className='ElectricDiv'>
                    <p className='FuelsNameText'>Energia</p>
                    <div className="CirleDivBack">
                        <p className='FuelPerscentigText'>{Station.Fuels[2]?.fuel}%</p>
                        <div
                            className="ElectricCirleDiv"
                            style={{ height: getHeight(Station.Fuels[2]?.fuel) }}
                        ></div>
                    </div>
                    <button
                        onClick={() => fetchNui("start-refill", "electric")}
                        className='StockBuyBt'>Indítás</button>
                </div>
            </div>


        </div>
    );
};

export default Dashboard;
