import { FC } from 'react';
import { Station } from '@/types/station';
import { fetchNui } from '@/utils/fetchNui';

interface ProfitProps {
    Station: Station;
}

const formatNumber = (num: number) => {
    return Math.round(num).toLocaleString('de-DE');
};

const Profit: FC<ProfitProps> = ({ Station }) => {
    const { income, tax } = Station;

    const taxAmount = Math.round((income * tax) / 100);
    const finalIncome = Math.round(income - taxAmount);


    const cashOut = () => {
        if (Station.income <= 1000) return
        fetchNui("cashout")
    }

    return (
        <div>
            <div className='w3-animate-top PageNameDiv'>
                <p className='PageNameText'>Bevétel</p>
            </div>
            <div className='w3-animate-bottom ProfitDiv'>
                <div className='CashCirleDivs'>
                    <div className='Cirlesbox'>
                        <p className='FuelsNameText'>Totál Kereset:</p>
                        <div className='ChashCirle'>
                            <p className='ChashTextMony'>{formatNumber(income)}$</p>
                        </div>
                    </div>
                    <div className='Cirlesbox'>
                        <p className='FuelsNameText'>Adó:</p>
                        <div className='TaxCirle'>
                            <div className='Chashbox'>
                                <p className='ChashTextMony'>-{formatNumber(taxAmount)}$</p>
                                <p className='ChashPresenteig ChashTextMony'>({tax}%)</p>
                            </div>
                        </div>
                    </div>
                </div>


                <div className='MathDiv'>
                    <div className="SzamolasRow">
                        <p className='SzamolasCimText'>Számolás:</p>
                    </div>
                    <div className="SzamolasRow">
                        <p className='SzamolasIncomeText'>{formatNumber(income)} $</p>
                    </div>
                    <div className="SzamolasRow">
                        <p className='SzamolasTaxText'>-{formatNumber(taxAmount)} $</p>
                    </div>
                    <div className="SzamolasRow">
                        <div className='SzamolasGrayLine'></div>
                    </div>
                    <div className="SzamolasRow">
                        <p className='SzamolasFinalText'>{formatNumber(finalIncome)} $</p>
                    </div>
                </div>
            </div>


            <div className='w3-animate-bottom Buyfooter'>
                <button
                    disabled={
                        Station.income <= 1000
                    }
                    onClick={cashOut}
                    className='GetOutCashBt'>Pénz Kivétele</button>
            </div>
        </div>
    );
};

export default Profit;
