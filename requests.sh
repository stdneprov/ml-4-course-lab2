#!/bin/bash
# test_simple.sh — простой тест для SMS Spam Classifier

BASE_URL="${BASE_URL:-http://localhost:8000}"
TIMEOUT=10

printf "🚀 SMS Spam Classifier — Тесты\n"
printf "📍 Endpoint: %s/generate\n\n" "$BASE_URL"

run_test() {
    local name="$1"
    local prompt="$2"
    local expected="$3"
    
    printf "📝 %s... " "$name"
    
    # Отправляем запрос с таймаутом
    local response
    response=$(curl -s --max-time "$TIMEOUT" -X POST "${BASE_URL}/generate" \
        -H "Content-Type: application/json" \
        -d "{\"prompt\": \"$prompt\"}" 2>&1)
    
    # Проверяем ошибку
    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        printf "❌ Ошибка запроса\n"
        return 1
    fi
    
    # Парсим ответ
    local answer
    answer=$(echo "$response" | jq -r '.answer // "error"' 2>/dev/null)
    
    # Сравниваем
    if [[ "$answer" == "$expected" ]]; then
        printf "✅ %s\n" "$answer"
        return 0
    else
        printf "❌ %s (ожидалось: %s)\n" "$answer" "$expected"
        return 1
    fi
}

# Тесты
run_test "Нормальное" "Привет, как дела?" "not spam"
run_test "Спам" "ВЫ ВЫИГРАЛИ АЙФОН!!! ЖМИ СЮДА!!!" "spam"
run_test "Код" "Ваш код: 12345" "not spam"
run_test "Фишинг" "Карта заблокирована. Подтвердите: http://fake.ru" "spam"

# Health check
printf "\n🩺 Health... "
if curl -sf --max-time "$TIMEOUT" "${BASE_URL}/health" >/dev/null 2>&1; then
    printf "✅ OK\n"
else
    printf "❌ FAIL\n"
fi

printf "\n✅ Готово\n"
