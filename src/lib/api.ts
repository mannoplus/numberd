export const getRecentMonths = (count: number) => {
    const months = []
    const d = new Date()
    for (let i = 0; i < count; i++) {
        const year = d.getFullYear()
        const month = String(d.getMonth() + 1).padStart(2, '0')
        months.push(`${year}-${month}`)
        d.setMonth(d.getMonth() - 1)
    }
    return months
}

export const fetchTaiwanLotteryApi = async (gameId: string, months: string[]) => {
    let endpoint = ''
    let resultsKey = ''

    if (gameId === 'lotto_649') {
        endpoint = 'Lotto649Result'
        resultsKey = 'lotto649Res'
    } else if (gameId === 'super_lotto_638') {
        endpoint = 'SuperLotto638Result'
        resultsKey = 'superLotto638Res'
    } else if (gameId === 'daily_cash_539') {
        endpoint = 'Daily539Result'
        resultsKey = 'daily539Res'
    }

    let allDraws: any[] = []

    const fetchWithTimeout = async (url: string, timeoutMs = 4000) => {
        try {
            const controller = new AbortController();
            const timer = setTimeout(() => controller.abort(), timeoutMs);
            const res = await fetch(url, { signal: controller.signal });
            clearTimeout(timer);
            if (res.ok) {
                return await res.json();
            }
            return null;
        } catch {
            return null;
        }
    };

    // Fetch all requested months concurrently with timeout
    const requests = months.map(m =>
        fetchWithTimeout(`https://api.taiwanlottery.com/TLCAPIWeB/Lottery/${endpoint}?period=&month=${m}`)
    );

    const responses = await Promise.all(requests);

    responses.forEach(data => {
        if (data && data.content && data.content[resultsKey]) {
            const draws = data.content[resultsKey].map((res: any) => {
                const rawNums = res.drawNumberSize || []
                let numbers = []
                let special_number = null

                if (gameId === 'lotto_649' || gameId === 'super_lotto_638') {
                    if (rawNums.length >= 7) {
                        numbers = rawNums.slice(0, 6)
                        special_number = rawNums[6]
                    }
                } else {
                    numbers = rawNums.slice(0, 5)
                }

                return {
                    draw_id: String(res.period),
                    game_type: gameId,
                    draw_date: (res.lotteryDate || '').split('T')[0],
                    numbers,
                    special_number
                }
            })
            allDraws = [...allDraws, ...draws]
        }
    })

    // Sort descending by date
    return allDraws.sort((a, b) => new Date(b.draw_date).getTime() - new Date(a.draw_date).getTime())
}
