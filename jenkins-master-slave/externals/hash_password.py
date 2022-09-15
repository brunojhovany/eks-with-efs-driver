import bcrypt
import sys
if not sys.argv[1]:
  sys.exit(10)
plaintext_pwd=bytes(sys.argv[1],'UTF-8')
encrypted_pwd=bcrypt.hashpw(plaintext_pwd, bcrypt.gensalt(rounds=10, prefix=b"2a"))
isCorrect=bcrypt.checkpw(plaintext_pwd, encrypted_pwd)
if not isCorrect:
  sys.exit(20);
print("{}".format(encrypted_pwd.decode()))