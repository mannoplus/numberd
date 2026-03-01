import { fetchTaiwanLotteryApi } from './src/lib/api.js';

async function test() {
    const result = await fetchTaiwanLotteryApi('super_lotto_638', ['2026-02']);
    console.log("Super Lotto 638:", JSON.stringify(result, null, 2));
}

test();
