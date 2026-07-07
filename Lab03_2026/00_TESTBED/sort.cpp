#include <iostream>
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <ctime>
bool comp(int &a, int &b) {
    if (a > b) {
        int temp = a;
        a = b;
        b = temp;
    }
    return a > b; // 返回是否交換了
}

void oddEvenSort(int arr[], int n) {
    // 必須連續兩步（奇+偶）都沒有交換，才算真正排序完成
    bool swapped_odd = true;
    bool swapped_even = true;

    for (int step = 1; step <= n; step++) {
        bool current_step_swapped = false;
        
        if (step % 2 != 0) {
            // Odd step
            for (int i = 1; i < n - 1; i += 2) {
                if (arr[i] > arr[i+1]) {
                    std::swap(arr[i], arr[i+1]);
                    current_step_swapped = true;
                }
            }
            swapped_odd = current_step_swapped;
        } else {
            // Even step
            for (int i = 0; i < n - 1; i += 2) {
                if (arr[i] > arr[i+1]) {
                    std::swap(arr[i], arr[i+1]);
                    current_step_swapped = true;
                }
            }
            swapped_even = current_step_swapped;
        }

        // 只有當一整輪（奇+偶）都沒有任何動作時，才退出
        if (!swapped_odd && !swapped_even) {
            std::cout << "提前於第 " << step << " 步停止。" << std::endl;
            break;
        }
    }
}

int main() {
    const int N = 256;
    int data[N];
srand(time(0));
    // 初始化一些測試數據 (倒序)
    for (int i = 0; i < N; i++) {
        data[i] = rand() % N;
    }

    std::cout << "排序前: " << std::endl;
    for(int i = 0; i < N; i++) {
        std::cout << data[i] << " ";
    }
    oddEvenSort(data, N);
    std::cout  << std::endl;
    std::cout << "排序後: " << std::endl;
    bool isSorted = true;
    for(int i = 1; i < N; i++) {
        if(data[i-1] > data[i]) {
            isSorted = false;
            break;
        }
    }
    if(isSorted) {
        std::cout << "排序成功!" << std::endl;
    } else {
        std::cout << "排序失敗!" << std::endl;
    }
    return 0;
}