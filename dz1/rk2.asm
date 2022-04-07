%include "lib64.asm"

%macro write_string 2
    ; вывод
    ; 1 - адрес строки, 2 - длина строки
    mov     rax, 1          ; системная функция 1 (write)
    mov     rdi, 1          ; дескриптор файла stdout=1
    mov     rsi, %1         ; адрес выводимой строки
    mov     rdx, %2         ; длина строки
    syscall                 ; вызов системной функции
%endmacro

%macro read_string 2
    ; ввод
    ; 1 - буфер ввода, 2 - длина буфера ввода
    mov     rax, 0          ; системная функция 0 (read)
    mov     rdi, 0          ; дескриптор файла stdin=0
    mov     rsi, %1         ; адрес вводимой строки
    mov     rdx, %2         ; длина строки
    syscall                 ; вызов системной функции
%endmacro

%macro IntToStr 2
    ; перевод integer в string
    mov     rsi, %2
    movsx   eax, byte %1        ; получение числа из памяти
    cwde
    call    IntToStr64          ; вызов процедуры
    cmp     rbx, 0              ; сравнение кода возврата
    jne     StrToInt64.Error    ; обработка ошибки         
%endmacro

    section .data           ; сегмент инициализированных переменных
ExitMsg     db      "Press Enter to Exit", 10 ; выводимое сообщение
lenExit     equ     $-ExitMsg
InputMsg    db      "Enter the line:", 10
lenInput    equ     $-InputMsg
OutputMsg   db      "The number of words no longer than 3 symbols: "
lenOutput   equ     $-OutputMsg
newLine     db      10

    section .bss                ; сегмент неинициализированных переменных
InBuf       resb    10          ; буфер для вводимой строки
lenIn       equ     $-InBuf     ; длина буфера для вводимой строки
OutBuf      resb    10
lenOut      equ     $-OutBuf
count       resb    1

    section .text           ; сегмент кода
    global _start

_start:

    write_string InputMsg, lenInput

    ; ввод строки
    sub rsp, 256     ; выделяем память для буфера ввода 
    
    read_string rsp, 256    ; выделяем память для ввода строки

    cmp byte [rsp], 10      ; если первый символ - enter, прыгаем в конец
    je break_while

    mov rcx, 0              ; rcx - индекс символа в строке, введенной пользователем
    mov rdx, 0              ; обнуляем счётчик символов в слове
    while:
        mov rbx, 0
        cmp byte [rsp + rcx], 32        ; сравниваем символ в строке с пробелом
        jne not_space                   ; если не пробел, прыгаем на not_space
        jmp end_of_word                 ; иначе прыгаем на end_of_word
        not_space:
            cmp byte [rsp + rcx], 10    ; сравниваем символ в строке с enter
            jne not_enter               ; если не enter, прыгаем на not_enter
            jmp end_of_word             ; иначе прыгаем на end_of_number
        not_enter:
            inc rdx                     ; увеличиваем счётчик символов в слове
            jmp continue                ; прыгаем на continue
        end_of_word:
            mov rax, rdx
            mov rdx, 0
            cmp rax, 4                  ; сравниваем кол-во символов в текущем слове с 4
            jl less                     ; если меньше, прыгаем на less
            jmp continue_end
            less:
                inc byte [count]        ; увеличиваем счётчик слов длины < 3
            continue_end:
                cmp byte [rsp + rcx], 10    ; сравниваем символ в строке с enter
                je break_while              ; если enter, то выходим из цикла
        continue:
            inc rcx                     ; переходим к следующему символу в строке
            jmp while                   ; переходим к следующей итерации цикла
    break_while:
        mov rbx, 0

    write_string newLine, 1
    write_string OutputMsg, lenOutput

    ; вывод количества слов
    IntToStr [count], OutBuf
    mov rbx, rax                        ; перекладываем длину строки в rbx, т.к. write_string работает с rax
    write_string OutBuf, rbx
    write_string newLine, 1

    ; завершение программы
    write_string ExitMsg, lenExit
    read_string InBuf, lenIn
    mov     rax, 60         ; системная функция 60 (exit)
    xor     rdi, rdi        ; return code 0    
    syscall                 ; вызов системной функции