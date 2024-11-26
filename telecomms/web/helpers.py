def find_user_in_db(login, list):
    for usr in list:
        if usr["login"] == login:
            return usr

    return None