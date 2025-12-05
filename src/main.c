#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <inttypes.h>
#include <errno.h>
#include <limits.h>

extern long long minmax_sum_asm(const int32_t* arr, size_t total,
                                int32_t* out_min, int32_t* out_max);

void show_usage(const char* exec_name) {
    fprintf(stderr, "Использование: %s M N [min max]\n", exec_name);
    fprintf(stderr, "Пример запуска: %s 4 5 -1000 1000\n", exec_name);
}

int32_t random_i32_in_range(int32_t lo, int32_t hi) {
    if (lo > hi) {
        int32_t swap = lo;
        lo = hi;
        hi = swap;
    }
    uint64_t value = ((uint64_t)rand() << 31) ^ (uint64_t)rand();
    uint64_t span = (uint64_t)hi - (uint64_t)lo + 1ULL;
    return (int32_t)(lo + (value % span));
}

int main(int argc, char* argv[]) {
    if (argc != 3 && argc != 5) {
        show_usage(argv[0]);
        return EXIT_FAILURE;
    }

    char* tail = NULL;
    errno = 0;
    unsigned long rows = strtoul(argv[1], &tail, 10);
    if (errno || !tail || *tail || rows == 0 || rows > 1000000UL) {
        fprintf(stderr, "Ошибка: некорректное значение количества строк (M).\n");
        return EXIT_FAILURE;
    }

    long cols = strtol(argv[2], &tail, 10);
    if (errno || !tail || *tail || cols <= 0 || cols > 1000000L) {
        fprintf(stderr, "Ошибка: некорректное значение количества столбцов (N).\n");
        return EXIT_FAILURE;
    }

    int32_t range_min = -100, range_max = 100;
    if (argc == 5) {
        long min_in = strtol(argv[3], &tail, 10);
        if (errno || !tail || *tail || min_in < INT32_MIN || min_in > INT32_MAX) {
            fprintf(stderr, "Ошибка: нижняя граница вне диапазона int32.\n");
            return EXIT_FAILURE;
        }
        long max_in = strtol(argv[4], &tail, 10);
        if (errno || !tail || *tail || max_in < INT32_MIN || max_in > INT32_MAX) {
            fprintf(stderr, "Ошибка: верхняя граница вне диапазона int32.\n");
            return EXIT_FAILURE;
        }
        if (min_in > max_in) {
            fprintf(stderr, "Ошибка: min не должен быть больше max.\n");
            return EXIT_FAILURE;
        }
        range_min = (int32_t)min_in;
        range_max = (int32_t)max_in;
    }

    if (rows > SIZE_MAX / (size_t)cols || ((size_t)rows * (size_t)cols) > SIZE_MAX / sizeof(int32_t)) {
        fprintf(stderr, "Ошибка: запрошенный размер матрицы слишком велик.\n");
        return EXIT_FAILURE;
    }
    size_t total_elems = (size_t)rows * (size_t)cols;

    int32_t* matrix = (int32_t*)malloc(total_elems * sizeof(int32_t));
    if (!matrix) {
        fprintf(stderr, "Не удалось выделить память: %zu элементов\n", total_elems);
        return EXIT_FAILURE;
    }

    srand((unsigned)time(NULL));
    printf("Создана матрица %lu x %ld (диапазон [%d, %d]):\n",
           rows, cols, range_min, range_max);

    for (size_t i = 0; i < rows; ++i) {
        for (size_t j = 0; j < (size_t)cols; ++j) {
            int32_t val = random_i32_in_range(range_min, range_max);
            matrix[i * (size_t)cols + j] = val;
            printf("%11" PRId32, val);
        }
        putchar('\n');
    }

    int32_t minimum = 0, maximum = 0;
    long long accum = minmax_sum_asm(matrix, total_elems, &minimum, &maximum);

    printf("\n");
    printf("Минимальный элемент: %" PRId32 "\n", minimum);
    printf("Максимальный элемент: %" PRId32 "\n", maximum);
    printf("Сумма min + max: %lld\n", accum);

    free(matrix);
    return EXIT_SUCCESS;
}
