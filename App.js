import "./App.css";
import { useEffect, useState } from "react";
import todoService from "./service/todo.service";
import "bootstrap/dist/css/bootstrap.min.css";

const App = () => {
  const [todos, setTodos] = useState([]);

  useEffect(() => {
    todoService
      .getAll()
      .then((res) => {
        console.log("printing todos", res.data);

        setTodos(res.data);
      })
      .catch((err) => {
        console.log("printing todos", err);
      });
  }, []);
  //47.05
  console.log("todo data", todos);
  return (
    <div className="container">
      <h3>List of todo</h3>
      <hr />
      <div>
        <table className="table table-striped table-bordered ">
          <thead className="thead-dark">
            <tr>
              <th>Todo</th>
              <th>Description</th>
              <th>Completed</th>
              <th>Created At</th>
            </tr>
          </thead>
          <tbody>
            {todos.map((todo) => (
              <tr key={todo.id}>
                <td>{todo.todo} </td>
                <td>{todo.description} </td>
                <td> {todo.completed ? "True" : "False"}</td>

                <td> {todo.createdAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default App;
