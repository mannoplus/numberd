import { createI18n } from 'vue-i18n'
import en from './locales/en.json'
import zhTW from './locales/zh-TW.json'

const savedLocale = localStorage.getItem('numberd-locale') || 'en'

export const i18n = createI18n({
    legacy: false, // Composition API mode
    locale: savedLocale,
    fallbackLocale: 'en',
    messages: {
        en,
        'zh-TW': zhTW
    }
})

export const formatLocalDate = (dateStr: string, locale: string) => {
    if (!dateStr) return '';
    if (locale === 'zh-TW') {
        const parts = dateStr.split('T')[0]?.split('-');
        if (parts && parts.length === 3) {
            const y = parts[0];
            const m = parts[1];
            const d = parts[2];
            if (y && m && d) {
                const rocYear = parseInt(y, 10) - 1911;
                return `民國 ${rocYear} 年 ${m} 月 ${d} 日`;
            }
        }
    }
    return dateStr;
}

export default i18n
