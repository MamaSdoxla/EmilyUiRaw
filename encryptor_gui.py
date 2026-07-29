import customtkinter as ctk
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import json
import os
import base64

# Настройка внешнего вида
ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class EmilyUiKeyManager(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("EmilyUi Key Manager")
        self.geometry("950x620")
        self.minsize(850, 520)
        self.settings_file = "settings.json"
        self.keys_database = []
        self.current_normal_path = None
        self.current_encrypted_path = None
        self.setup_ui()
        self.load_settings()
        self.protocol("WM_DELETE_WINDOW", self.on_closing)

    def setup_ui(self):
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(2, weight=1)

        # --- ВЕРХНЯЯ ПАНЕЛЬ ---
        top_frame = ctk.CTkFrame(self)
        top_frame.grid(row=0, column=0, padx=10, pady=(10, 5), sticky="ew")
        top_frame.grid_columnconfigure(1, weight=1)

        ctk.CTkLabel(top_frame, text="Secret Key:", font=("Roboto", 14, "bold")).grid(row=0, column=0, padx=10, pady=10)
        self.entry_secret_key = ctk.CTkEntry(top_frame, width=250)
        self.entry_secret_key.grid(row=0, column=1, padx=10, pady=10, sticky="w")

        self.btn_open_normal = ctk.CTkButton(top_frame, text=" Открыть JSON", command=self.open_normal_json, width=140)
        self.btn_open_normal.grid(row=0, column=2, padx=5, pady=10)

        self.btn_open_encrypted = ctk.CTkButton(top_frame, text="🔐 Зашифрованный", command=self.open_encrypted_json, fg_color="#8B0000", hover_color="#5C0000", width=140)
        self.btn_open_encrypted.grid(row=0, column=3, padx=5, pady=10)

        self.btn_save_file = ctk.CTkButton(top_frame, text="💾 Сохранить данные", command=self.save_data_dialog, fg_color="#2b823e", hover_color="#1e5c2b", width=150)
        self.btn_save_file.grid(row=0, column=4, padx=10, pady=10)

        # --- ПАНЕЛЬ ДОБАВЛЕНИЯ ---
        add_frame = ctk.CTkFrame(self)
        add_frame.grid(row=1, column=0, padx=10, pady=5, sticky="ew")
        for i in range(5):
            add_frame.grid_columnconfigure(i, weight=1)

        self.entry_key = ctk.CTkEntry(add_frame, placeholder_text="Ключ")
        self.entry_key.grid(row=0, column=0, padx=5, pady=10, sticky="ew")

        self.entry_robloxid = ctk.CTkEntry(add_frame, placeholder_text="Roblox ID (или 'none')")
        self.entry_robloxid.grid(row=0, column=1, padx=5, pady=10, sticky="ew")

        # ИСПРАВЛЕНО: роли с заглавной буквы как в Lua
        self.combo_role = ctk.CTkComboBox(add_frame, values=["Free", "User", "Tester", "Coder"], state="readonly")
        self.combo_role.set("Free")
        self.combo_role.grid(row=0, column=2, padx=5, pady=10, sticky="ew")

        # ИСПРАВЛЕНО: формат даты DD.MM.YYYY как в Lua
        self.entry_expiration = ctk.CTkEntry(add_frame, placeholder_text="Срок (DD.MM.YYYY / inf)")
        self.entry_expiration.grid(row=0, column=3, padx=5, pady=10, sticky="ew")

        btn_action_frame = ctk.CTkFrame(add_frame, fg_color="transparent")
        btn_action_frame.grid(row=0, column=4, padx=5, pady=5, sticky="ew")
        btn_action_frame.grid_columnconfigure((0, 1), weight=1)

        self.btn_add_key = ctk.CTkButton(btn_action_frame, text="Добавить", command=self.add_key, width=90)
        self.btn_add_key.grid(row=0, column=0, padx=2, pady=5)

        self.btn_delete_key = ctk.CTkButton(btn_action_frame, text="Удалить", command=self.delete_selected_key, fg_color="#a83232", hover_color="#782222", width=90)
        self.btn_delete_key.grid(row=0, column=1, padx=2, pady=5)

        # --- ТАБЛИЦА ---
        table_frame = ctk.CTkFrame(self)
        table_frame.grid(row=2, column=0, padx=10, pady=(5, 10), sticky="nsew")
        table_frame.grid_columnconfigure(0, weight=1)
        table_frame.grid_rowconfigure(0, weight=1)

        self.style_treeview()
        columns = ("key", "robloxid", "role", "expiration")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", style="Custom.Treeview")
        self.tree.heading("key", text="Ключ")
        self.tree.heading("robloxid", text="Roblox ID")
        self.tree.heading("role", text="Роль")
        self.tree.heading("expiration", text="Срок действия")
        self.tree.column("key", width=260)
        self.tree.column("robloxid", width=200)
        self.tree.column("role", width=120)
        self.tree.column("expiration", width=150)
        self.tree.grid(row=0, column=0, sticky="nsew")

        scrollbar = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscroll=scrollbar.set)
        scrollbar.grid(row=0, column=1, sticky="ns")

    def style_treeview(self):
        style = ttk.Style()
        style.theme_use("default")
        style.configure("Custom.Treeview",
                        background="#2b2b2b", foreground="white",
                        rowheight=30, fieldbackground="#2b2b2b",
                        bordercolor="#343638", borderwidth=0,
                        font=("Roboto", 11))
        style.map('Custom.Treeview', background=[('selected', '#1f538d')])
        style.configure("Custom.Treeview.Heading",
                        background="#343638", foreground="white",
                        relief="flat", font=("Roboto", 11, "bold"))
        style.map("Custom.Treeview.Heading", background=[('active', '#1f538d')])

    # --- НАСТРОЙКИ ---
    def load_settings(self):
        if os.path.exists(self.settings_file):
            try:
                with open(self.settings_file, "r", encoding="utf-8") as f:
                    settings = json.load(f)
                    if "SecretKey" in settings:
                        self.entry_secret_key.insert(0, settings["SecretKey"])
                    if "NormalPath" in settings:
                        self.current_normal_path = settings["NormalPath"]
                    if "EncryptedPath" in settings:
                        self.current_encrypted_path = settings["EncryptedPath"]
            except Exception:
                pass

    def save_settings(self):
        settings = {
            "SecretKey": self.entry_secret_key.get(),
            "NormalPath": self.current_normal_path,
            "EncryptedPath": self.current_encrypted_path
        }
        with open(self.settings_file, "w", encoding="utf-8") as f:
            json.dump(settings, f, indent=4, ensure_ascii=False)

    def on_closing(self):
        self.save_settings()
        self.destroy()

    # --- ОТКРЫТИЕ ФАЙЛОВ ---
    def open_normal_json(self):
        file_path = filedialog.askopenfilename(filetypes=[("JSON files", "*.json"), ("All files", "*.*")])
        if file_path:
            try:
                self.current_normal_path = file_path
                self.save_settings()
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read().strip()
                if not content:
                    self.keys_database = []
                    self.update_grid()
                    return
                self.load_data_to_grid(content)
            except Exception as e:
                messagebox.showerror("Ошибка", f"Не удалось прочитать файл:\n{str(e)}")

    def open_encrypted_json(self):
        file_path = filedialog.askopenfilename(filetypes=[("JSON files", "*.json"), ("All files", "*.*")])
        if file_path:
            secret_key = self.entry_secret_key.get()
            if not secret_key:
                messagebox.showwarning("Внимание", "Введите Secret Key для расшифровки.")
                return
            try:
                self.current_encrypted_path = file_path
                self.save_settings()
                with open(file_path, "r", encoding="utf-8") as f:
                    encrypted_base64 = f.read().strip()
                if not encrypted_base64:
                    self.keys_database = []
                    self.update_grid()
                    return
                decrypted_json = self.decrypt_string(encrypted_base64, secret_key)
                if not decrypted_json.strip():
                    self.keys_database = []
                    self.update_grid()
                else:
                    self.load_data_to_grid(decrypted_json)
            except Exception as e:
                messagebox.showerror("Ошибка", f"Ошибка расшифровки! Проверьте Secret Key.\n\n{str(e)}")

    def load_data_to_grid(self, json_text):
        try:
            data = json.loads(json_text)
            if isinstance(data, list):
                self.keys_database = data
            else:
                self.keys_database = []
            self.update_grid()
        except json.JSONDecodeError as e:
            messagebox.showerror("Ошибка", f"Ошибка структуры JSON:\n{str(e)}")

    def update_grid(self):
        for item in self.tree.get_children():
            self.tree.delete(item)
        for entry in self.keys_database:
            # ИСПРАВЛЕНО: имена полей как в Lua
            self.tree.insert("", "end", values=(
                entry.get("key", ""),
                entry.get("robloxName", ""),
                entry.get("group", ""),
                entry.get("timeTillWorks", "")
            ))

    # --- УПРАВЛЕНИЕ ДАННЫМИ ---
    def add_key(self):
        key_val = self.entry_key.get().strip()
        robloxid_val = self.entry_robloxid.get().strip()
        role_val = self.combo_role.get()
        exp_val = self.entry_expiration.get().strip()

        if not key_val:
            messagebox.showwarning("Внимание", "Поле 'Ключ' обязательно для заполнения.")
            return
        if not exp_val:
            exp_val = "inf"

        # ИСПРАВЛЕНО: имена полей как в Lua
        new_entry = {
            "key": key_val,
            "robloxName": robloxid_val if robloxid_val else "none",
            "group": role_val,
            "timeTillWorks": exp_val
        }
        self.keys_database.append(new_entry)
        self.update_grid()
        self.entry_key.delete(0, tk.END)
        self.entry_robloxid.delete(0, tk.END)
        self.entry_expiration.delete(0, tk.END)
        self.combo_role.set("Free")

    def delete_selected_key(self):
        selected_items = self.tree.selection()
        if not selected_items:
            messagebox.showwarning("Внимание", "Выберите строку в таблице для удаления.")
            return
        for item in selected_items:
            index = self.tree.index(item)
            del self.keys_database[index]
        self.update_grid()

    # --- СОХРАНЕНИЕ ---
    def save_data_dialog(self):
        if not self.keys_database and not self.current_normal_path and not self.current_encrypted_path:
            messagebox.showwarning("Внимание", "Нет данных для сохранения и файлы не были открыты.")
            return

        saved_count = 0
        try:
            json_data = json.dumps(self.keys_database, indent=4, ensure_ascii=False)

            if self.current_normal_path:
                with open(self.current_normal_path, "w", encoding="utf-8") as f:
                    f.write(json_data)
                saved_count += 1

            if self.current_encrypted_path:
                secret_key = self.entry_secret_key.get()
                if not secret_key:
                    messagebox.showwarning("Внимание", "Secret Key пуст! Зашифрованный файл не может быть обновлен.")
                else:
                    encrypted_data = self.encrypt_string(json_data, secret_key)
                    with open(self.current_encrypted_path, "w", encoding="utf-8") as f:
                        f.write(encrypted_data)
                    saved_count += 1

            if saved_count == 0:
                messagebox.showwarning("Внимание", "Не найдены ранее открытые файлы для сохранения.")
                return

            messagebox.showinfo("Успех", "Данные успешно сохранены!")
        except Exception as e:
            messagebox.showerror("Ошибка", f"Не удалось сохранить файлы:\n{str(e)}")

    # ==========================================
    # КРИПТОГРАФИЯ: XOR + Base64 (совместимо с Lua)
    # ==========================================
    def encrypt_string(self, plain_text, key_string):
        """XOR-шифрование + Base64 — совместимо с Lua-дешифратором"""
        key_bytes = key_string.encode('utf-8')
        plain_bytes = plain_text.encode('utf-8')
        result = bytearray()
        for i in range(len(plain_bytes)):
            result.append(plain_bytes[i] ^ key_bytes[i % len(key_bytes)])
        return base64.b64encode(bytes(result)).decode('utf-8')

    def decrypt_string(self, cipher_text_b64, key_string):
        """Base64 декодирование + XOR-расшифрование — совместимо с Lua"""
        raw_bytes = base64.b64decode(cipher_text_b64)
        key_bytes = key_string.encode('utf-8')
        result = bytearray()
        for i in range(len(raw_bytes)):
            result.append(raw_bytes[i] ^ key_bytes[i % len(key_bytes)])
        return result.decode('utf-8')


if __name__ == "__main__":
    app = EmilyUiKeyManager()
    app.mainloop()