"""Interactive local confirmation: fails closed without a graphical session."""

def confirm_message(data):
    try:
        import tkinter as tk
        from tkinter import ttk
        root = tk.Tk()
        root.title('Webglobe Mail Connector – potvrdenie odoslania')
        root.geometry('760x670')
        root.minsize(600,500)
        root.attributes('-topmost', True)
        frame = ttk.Frame(root,padding=12)
        frame.pack(fill='both',expand=True)
        ttk.Label(frame, text='Skontrolujte CELÝ e-mail. Odoslanie je nevratné.', font=('Segoe UI',11,'bold')).pack(anchor='w',pady=(0,10))
        for title, field in (('Od:', 'from'),('Komu:', 'to'),('Kópia:', 'cc'),('Skrytá kópia:', 'bcc'),('Predmet:', 'subject')):
            value = ', '.join(data[field]) if isinstance(data[field],list) else data[field]
            ttk.Label(frame,text=title+' '+value,wraplength=690).pack(anchor='w',pady=2)
        ttk.Label(frame,text='Obsah správy (iba na čítanie):').pack(anchor='w',pady=(12,4))
        bodyframe = ttk.Frame(frame);bodyframe.pack(fill='both',expand=True)
        box = tk.Text(bodyframe,wrap='word',height=12)
        scroll = ttk.Scrollbar(bodyframe,orient='vertical',command=box.yview)
        box.configure(yscrollcommand=scroll.set)
        box.pack(side='left',fill='both',expand=True)
        scroll.pack(side='right',fill='y')
        box.insert('1.0',data['body']);box.configure(state='disabled')
        approved=[False]
        buttons=ttk.Frame(frame);buttons.pack(fill='x',pady=(14,4))
        def cancel(): root.destroy()
        def send(): approved[0]=True;root.destroy()
        ttk.Button(buttons,text='Zrušiť (neodosielať)',command=cancel).pack(side='right',padx=5)
        ttk.Button(buttons,text='Potvrdzujem – ODOSLAŤ',command=send).pack(side='right',padx=5)
        root.protocol('WM_DELETE_WINDOW',cancel)
        root.mainloop()
        return approved[0]
    except Exception:
        # Never send when the GUI cannot be displayed.
        return False
